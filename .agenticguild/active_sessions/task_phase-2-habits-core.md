% Task: phase-2-habits-core
% Goal: Design and implement the core habits system (Phase 2 of ROADMAP) with global templates, per-user instances, default seeded habits, categories, and activation/deactivation semantics, all consistent with Phase 1 auth/profile foundations.

---

## Discovery Log

### Decisions Made (so far)

1. **Ownership model**
   - Habits have **global templates** plus **per-user instances**.
   - Each user can choose which templates to use; there is a principal/default template set that is enabled by default.
   - Per-user habits **must not share the exact same name among active habits**; inactive habits may reuse a historical name.
   - Name uniqueness is enforced **case-insensitively** and on **trimmed** values (e.g. `"Agua" == "agua" == "Agua "`).
   - Users can also create **personal habits** (custom habits) not backed by a global template.
   - Converting personal habits into reusable templates is explicitly **out of scope** for Phase 2 (Backlog candidate).

2. **Frequencies & calendar semantics**
   - Supported frequency types: **daily**, **specific weekdays**, **every X days**, **weekly**, **monthly** (per ROADMAP).
   - `every X days` counts from the **activation date** of the habit, not from creation time.
   - `monthly` means: repeat on the **same calendar day-of-month as the activation date**.
     - If the day does not exist in a given month, use the **last valid calendar day of that month** (normal calendar behavior):  
       - Feb: 28 or 29 (leap years)  
       - 30-day months: 30  
       - 31-day months: 31
   - For **weekly / specific weekdays**, if the user later changes their timezone, the effective weekdays must be **recomputed for the new timezone**, and downstream tracking (Phase 3) must respect this.
   - Historical interpretation uses only the **user's current timezone**; we are **not** preserving per-habit historical timezone snapshots in Phase 2.

3. **Categories**
   - Categories are **per user**, not global.
   - Deleting a category that still has habits assigned is **blocked**; user must first reassign or deactivate those habits.
   - No explicit visual ordering, color, or emoji in Phase 2; those go to a future backlog item.

4. **Default (seeded) habits**
   - Default habits are:  
     - **Alimentación**: Desayuno, Almuerzo, Cena, Merienda  
     - **Salud Física**: Ejercicio, Agua  
     - **Emocional**: Mascota  
   - These defaults must be **seeded per user** the first time we need them, but:
     - They **may be created on the user's first login after signup** (not necessarily within the signup transaction).
     - If the seeding fails, it must **not break signup**; errors should be logged and retried through a **background job** until the defaults are provisioned successfully.
     - The seed job must be **idempotent by template code** so it can retry safely without creating duplicates.
   - Users **cannot delete** these default habits; they can only **deactivate** them.
   - Names, categories, and any user-facing strings must support **i18n** from the start (no hard-coded Spanish-only strings in code).

5. **Activate / deactivate behavior**
   - Deactivating a habit must **never delete historical tracking data** (once Phase 3 is implemented).
   - When reactivating a habit, the user is allowed to **reconfigure** it in the same flow (frequency, category, etc.), rather than restoring the previous configuration blindly.
   - Habits are **not deleted** in Phase 2 (including personal habits). Users only **deactivate** habits.

6. **Environment / migration assumptions**
   - Current environment is **development only**; there are no real production users yet.
   - This allows us to **seed default habits retroactively for all existing users** when Phase 2 is deployed, without complex data migration concerns.

---

## Domain Model (initial sketch)

> This section will be iterated as we refine requirements and edge cases. Value Objects / Branded Types should be introduced where raw primitives would be unsafe or ambiguous.

### Value Objects / Branded Types (approved)

- **TemplateCode** (`String`)
  - Stable, locale-neutral identifier for `GlobalHabitTemplate`.
  - **Format:** lowercase `snake_case` in English (e.g. `nutrition_breakfast`, `fitness_water`).
  - Used for idempotent seeding and job retries.

- **HabitName** (`String`)
  - User-facing name, with a normalized form used for uniqueness checks.
  - **Normalization for comparison:** `strip` + `downcase`.
  - Implementation intent: persist `name` (original) and `name_normalized` (comparison key).

- **FrequencyType** (enum / constrained `String`)
  - One of: `daily`, `weekdays`, `every_x_days`, `weekly`, `monthly`.

- **WeekdaySet** (validated collection)
  - Used when `FrequencyType=weekdays`.
  - Representation: array of integers **0–6** (no duplicates).

- **EveryXDays** (`Integer`)
  - Used when `FrequencyType=every_x_days`.
  - Invariant: \(x \ge 1\).

- **ActivationDate** (`Date`)
  - Activation date used as the anchor for schedule semantics (especially `every_x_days` and `monthly`).

- **DayOfMonth** (`Integer`)
  - Used when `FrequencyType=monthly`.
  - Invariant: 1–31; derived from `ActivationDate`.

### GlobalHabitTemplate

- **Responsibility:** Define a reusable habit template (name, description, default frequency, default category semantics) that can be instantiated per user.
- **Invariants:**
  - Has a stable identifier used for seeding and migration (e.g. a code or slug).
  - Template `code` is stable and **English** (recommended) to remain locale-neutral; display labels come from i18n.
  - Name is i18n-backed; no hard-coded plain strings in the Ruby model.
  - Cannot be hard-deleted once in use; only soft-deactivated for future users if needed.

### UserHabit

- **Responsibility:** Represent a user-specific instance of a habit, derived from a template or created ad-hoc.
- **Invariants:**
  - Belongs to a User.
  - Has a unique **active name per user** (case-insensitive, trimmed; no duplicates among active habits).
  - Stores **frequency type** and its parameters (e.g. X for every X days, set of weekdays for specific weekdays).
  - Has **activation state** (active/inactive) and an **activation date** used to compute schedules.
  - If derived from a `GlobalHabitTemplate`, keeps a reference to it for future reporting / migration.

### HabitCategory

- **Responsibility:** Group a user's habits under user-defined (or default) labels such as Alimentación, Salud Física, Emocional.
- **Invariants:**
  - Belongs to a User.
  - Cannot be deleted while any `UserHabit` references it.
  - Has a unique name per user.
  - Seeded “default” categories are still user-owned: the user may **rename** them later (i18n provides the starting label only).

---

## Open Questions / To Refine

✅ All previously-open questions have been resolved for Phase 2 scope.

---

## Status

- **Phase:** 1 — Discovery for Phase 2 Habits Core
- **Ready for implementation_plan?** Yes — spec considered complete for Phase 2.

---

<implementation_plan>
<task_name>phase-2-habits-core</task_name>
<task_type>Feature</task_type>
<status>ready</status>
<classification_rules>
  Feature: All steps are test-first (Red → Green → Refactor). No production code written before a failing test.
</classification_rules>

<scope_mapping>
  <roadmap_items>
    <item id="5">Habit model with frequency types (daily, weekdays, every X days, weekly, monthly)</item>
    <item id="6">Default habits seeded per user on first login (job retries; idempotent)</item>
    <item id="7">User-managed categories (create, edit, delete w/ blocking)</item>
    <item id="8">Habits displayed grouped by category</item>
    <item id="9">Activate / deactivate habits (defaults can be deactivated; history preserved)</item>
  </roadmap_items>
</scope_mapping>

<steps>

  <step id="1" title="[TDD] Introduce core entities (templates, categories, user habits)" status="complete">
    <action>**RED:** Write model specs for: `GlobalHabitTemplate`, `HabitCategory`, `UserHabit` (names provisional) covering associations and invariants:
      - Each is scoped appropriately (`user_id` for per-user models).
      - Active name uniqueness: a user cannot have two active habits with exactly the same name (case-insensitive, trimmed).
      - Category name uniqueness per user.
      - Category deletion blocked if any `UserHabit` references it.
      - Personal habits allowed: `UserHabit` may have nil `global_habit_template_id`.
    </action>
    <action>Generate migrations + models. Run `rails db:migrate` and `rspec` until green.</action>
    <action>**REFACTOR:** Extract shared validators/scopes as needed; keep business rules in models or service objects (avoid controller logic).</action>
  </step>

  <step id="2" title="[TDD] Frequency representation & schedule semantics (Phase 2 only)" status="complete">
    <action>**RED:** Add unit tests validating that `UserHabit` can represent and validate:
      - daily
      - specific weekdays (store as a set/array of weekdays)
      - every X days (integer X ≥ 1) counted from activation date
      - weekly
      - monthly (stores day-of-month derived from activation date; months without that day clamp to the month's last day; e.g. Jan 31 → Feb 28/29 → Mar 31)
    </action>
    <action>**GREEN:** Implement validations + persistence shape for frequency (e.g. `frequency_type` + `frequency_params` JSON). Ensure activation date is persisted and required for schedule-driven frequencies.</action>
    <action>**REFACTOR:** Keep schedule logic encapsulated (pure functions/module) so Phase 3 can reuse it for “Mi Día”.</action>
  </step>

  <step id="3" title="[TDD] Seeding: default templates + per-user provisioning job (idempotent, retrying)" status="complete">
    <action>**RED:** Write specs for:
      - A stable template identifier (e.g. `code`) and uniqueness.
      - Seeding global templates is idempotent by `code`.
      - Per-user provisioning is idempotent: running the job multiple times does not create duplicates.
      - Default habits are created on first login (or a hook that runs immediately after login) and failures enqueue retries without blocking login.
    </action>
    <action>**GREEN:** Implement:
      - A seed mechanism for global templates (codes + i18n keys rather than hard-coded Spanish strings).
      - A background job `ProvisionDefaultHabitsJob` (name provisional) that provisions categories + user habits for a user from the principal template set, using upserts / find-or-create by template code.
      - Hook the job to run after first successful login (and/or when user has no provisioned defaults).
    </action>
    <action>**REFACTOR:** Ensure job is safe to run concurrently (unique constraints where appropriate) and logs failures.</action>
  </step>

  <step id="4" title="[TDD] Categories CRUD (user-managed, deletion blocked when referenced)" status="complete">
    <action>**RED:** System/request specs for category create/edit/delete flows:
      - Auth required.
      - Users can create and rename categories.
      - Deleting a category with assigned habits is blocked with a user-facing error.
      - User can rename seeded default categories.
    </action>
    <action>**GREEN:** Implement controller/actions + views (Rails + Hotwire where appropriate) for categories.</action>
    <action>**REFACTOR:** Keep authorization and scoping correct (no cross-user access).</action>
  </step>

  <step id="5" title="[TDD] Habits UI grouped by category + activation/deactivation + template selection" status="complete">
    <action>**RED:** System specs covering:
      - Habits index renders grouped by category.
      - User can activate/deactivate habits; default ones can be deactivated but not deleted.
      - User can create a personal habit.
      - User can select from available templates (enable/disable) and reconfigure on reactivation.
      - Name uniqueness enforcement among active habits shows friendly validation errors.
      - No UI path exists to delete habits; attempting destructive actions is not available/blocked.
    </action>
    <action>**GREEN:** Implement:
      - Habits index grouped by category.
      - Habit create/edit flows for personal habits and template-derived habits.
      - Activation toggle and reactivation flow that allows reconfiguration.
    </action>
    <action>**REFACTOR:** Extract habit mutation logic into service objects if controllers get complex.</action>
  </step>

  <step id="6" title="Regression: full suite green baseline" status="complete">
    <action>Run full `rspec` suite; all examples must pass (0 failures).</action>
  </step>

</steps>

<verification_checklist>
  - [ ] Global templates exist with stable `code` identifiers and i18n-backed labels
  - [ ] Users can create personal habits (no template)
  - [ ] Active habit names are unique per user (inactive may reuse)
  - [ ] Active habit name uniqueness is case-insensitive and trimmed
  - [ ] Frequency types supported with correct persisted params and validation
  - [ ] Monthly behavior: missing day-of-month clamps to last valid day (Jan 31 → Feb 28/29 → Mar 31)
  - [ ] Categories CRUD works; deletion blocked when habits reference the category
  - [ ] Habits index grouped by category
  - [ ] Activation/deactivation works; habits are not deletable (only deactivatable); defaults retain history
  - [ ] Default provisioning runs on first login via a retrying, idempotent background job
  - [ ] Full RSpec suite green
</verification_checklist>

</implementation_plan>

