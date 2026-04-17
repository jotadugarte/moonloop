# Task: Phase 4 — Menus & Recipes (Alimentación)

## Goal
Deliver the full Phase 4 roadmap slice (items 15–19) for “Alimentación”:

- Weekly **Menu** planning (one entry per day-of-week per meal type)
- **Recipes** with instructions and image upload (plus default/fallback images per meal type)
- A **Phase system** mapping week ranges to menus (anchored by a user-defined Phase 1 start date)
- **Phase alerts** (warning + reminders when phases begin)
- **Phase extension** UX when the configured plan ends

This file is the discovery “whiteboard” for the feature; no application code should be written from here directly.

## Inputs (source of truth)
- `docs/ROADMAP.md`: Phase 4 items 15–19
- `docs/core/SYSTEM_ARCHITECTURE.md`: Rails 8.1 + Hotwire + ActiveStorage + Solid Queue; service-object boundary; I18n; REQ traceability
- `docs/core/SPEC.md`: reserves `REQ-MENU-001 … REQ-MENU-005` (details to be defined here and then encoded into specs/tests later)

## Scope (what we will build)
### (REQ-MENU-001) Weekly menu plan
- A **Menu** is a reusable weekly plan.
- A Menu contains **MealEntries** such that for each:
  - **meal_type** ∈ {`desayuno`, `almuerzo`, `cena`, `merienda`} (aligned with default habits)
  - **weekday** ∈ 0..6 (0=Sunday … 6=Saturday)
  - Exactly **one entry** per `(menu, meal_type, weekday)` (enforced by constraint)
- An entry references either:
  - a **Recipe** (preferred), or
  - a free-form text fallback (optional; to support “simple” meals without recipe authoring)

### (REQ-MENU-002) Recipe model
- **Recipe** fields:
  - `name` (required)
  - `instructions` (rich text or plain text; default to plain text unless stack already includes ActionText)
  - `image` upload via **ActiveStorage**
- **Default image per meal type**:
  - If a recipe has no uploaded image, the UI displays a fallback image based on the meal type context where it is shown.
  - (Decision point) If the recipe is used in multiple meal types, fallback should be stable and predictable (see “Open questions”).

### (REQ-MENU-003) Phase system (week ranges → menus)
- User defines a **Phase 1 start date** (anchor) for the “program”.
- User configures **week ranges** that map to a Menu, e.g.:
  - weeks 1–4 → Menu A
  - weeks 5–12 → Menu B
- The “active week” for a given local date is computed from the user’s timezone + the anchor date:
  - `week_index = floor((local_date - phase1_start_date) / 7) + 1` for local_date >= start_date
  - dates before start_date are “pre-phase” (no active assignment)
- At most one menu assignment applies to any given week index.

### (REQ-MENU-004) Alerts
- When a user sets Phase 1 start date:
  - warn if the start date is **more than 3 days in the future**
- Reminder:
  - send a reminder **on the day a phase begins** (interpreted in the user’s timezone)
- Delivery mechanism:
  - baseline: in-app notification/banner and/or email depending on **per-user preferences**
  - scheduling via **Solid Queue** (daily sweep job is likely simplest)

### (REQ-MENU-005) Phase extension
- When the configured plan ends (the last assigned week is in the past relative to “current week”):
  - prompt the user to either:
    - repeat the last phase/menu assignment (extend by N weeks), or
    - add a new week range with a selected menu

## Non-goals (explicitly out of scope for Phase 4)
- Nutrition macros/calories, shopping lists, ingredient databases
- Push notifications (explicitly out of Phase 4 unless added later)
- Integration into “Mi Día” habit tracking UI (unless explicitly requested; roadmap does not yet require it)

## Product decisions captured
- **Ownership + sharing**: Menus and Recipes are user-owned by default; the user may mark them as **shareable** so other users can use them.
- **Sharing semantics**: when another user uses a shared Menu/Recipe, the system creates a **copy** owned by the importing user (no live reference to the original).
- **Recipe fallback image**: **context-based (Opción A)** — when shown in a MenuEntry, fallback image depends on that slot’s `meal_type` if the recipe has no uploaded image.
- **Phase reminders**: may be in-app and/or email; user can configure which channels they want.
- **Mi Día integration**: Menus/Phase access is an in-screen shortcut below “Mi Día” (same screen), not a separate top-level area.
- **MenuEntry content**: Opción 3 — allow Recipe and/or freeform text, gated by a **per-user preference** (“recipes-only” vs “allow freeform”).

## Edge cases / dark corners / common mistakes (Phase 4)
### Sharing & copies
- **Owner edits after others import**: because imports create a **copy**, edits to the original must **not** affect imported copies. UX should clarify “copied into your library”.
- **Unshare after import**: unsharing should not delete others’ copies; it only affects future discoverability.
- **Deletion of shared original**: should not break imported copies.
- **Accidental sharing**: keep sharing explicit (toggle + confirmation); consider a “public” badge + last-shared timestamp.
- **Attribution** (optional): if we track provenance (`original_*_id`), ensure it is nullable and safe if original is deleted.

### MenuEntry validation conflicts
- **Empty slot**: prefer sparse records—UI grid renders empty slots without storing rows for every slot.
- **Both empty**: if freeform is enabled, still enforce “at least one of recipe_id or freeform_text”.
- **Both present**: decide allow vs forbid. If allowed, define UI priority (display recipe + note). If forbidden, enforce XOR.
- **Preference toggled after data exists**: if user disables freeform, define whether existing freeform entries remain visible (read-only) vs must be converted (avoid silent data loss).

### Week calculation & timezone
- **Anchor date**: Phase 1 start date is a *local date* in the user’s timezone; never treat it as UTC midnight.
- **Week 1 semantics**: week 1 begins on the anchor date, not aligned to calendar week boundaries.
- **User timezone changes**: define whether the active week recomputes using the new timezone (recommended: yes, consistent with “Mi Día” philosophy).

### Week-range assignments
- **Overlaps**: reject via validation; adjacency is OK (1–4 and 5–12).
- **Gaps**: if no assignment exists for the current week, show “no menu assigned” rather than error.
- **Large ranges**: UX should emphasize current week and nearby ranges to avoid long scrolling.

### Reminders / alerts
- **3-days warning**: clarify whether it appears only at save-time or persists until within 3 days.
- **Duplicate reminders**: sweep jobs must be idempotent; persist a sent marker per (user, phase_start_local_date or week_index).
- **Preference logic**: if email disabled, still show in-app if enabled; if both disabled, send nothing.
- **Testing trap**: timezone boundaries around “today” are a common source of flaky tests.

### Phase extension prompt
- **Plan ended**: when current week index > max_assigned_week. Edge: user has no assignments at all.
- **Repeat last phase**: define whether “repeat” adds a new contiguous range of the same length or simply extends the last range.

## Domain Model
### Entities
- **Menu**
  - Responsibility: reusable weekly template (7 days × meal types)
  - Invariants:
    - belongs to a `User`
    - unique `name` per user (case-insensitive) is recommended
    - may be marked **publicly shareable** (public browse/search); admin may revoke sharing for moderation
- **MenuEntry**
  - Responsibility: a single planned meal slot in a Menu
  - Invariants:
    - exactly one per `(menu_id, weekday, meal_type)`
    - either `recipe_id` present OR `freeform_text` present (at least one)
- **Recipe**
  - Responsibility: reusable cooking instruction artifact
  - Invariants:
    - belongs to a `User`
    - `name` required; optional instructions; optional image attachment
    - may be marked **publicly shareable** (public browse/search); admin may revoke sharing for moderation
- **PhasePlan** (name provisional)
  - Responsibility: stores the user’s Phase 1 start date
  - Invariants:
    - one per user (or keep on `User` as a field; decision point)
- **PhaseAssignment**
  - Responsibility: maps a week range to a Menu
  - Invariants:
    - belongs to user (or to PhasePlan)
    - week ranges do not overlap for the same user
    - start_week >= 1, end_week >= start_week

### Value Objects / Branded Types (conceptual)
- `MealType` (enum): breakfast/lunch/dinner/snack (`desayuno`, `almuerzo`, `cena`, `merienda`)
- `WeekIndex` (positive int ≥ 1)
- `WeekRange` (start_week..end_week)
- `LocalDate` (civil date in user timezone)

### Ruby Value Objects (approved for implementation)
These are the concrete wrappers to use in services (avoid raw `String`/`Integer`/`Date` for these concepts):

- **`Menus::MealType`**
  - Wraps: canonical string key
  - Allowed values: `desayuno`, `almuerzo`, `cena`, `merienda`
  - Validation: reject unknown keys; normalize input (strip + downcase) if we accept user-ish input at boundaries

- **`Menus::Weekday`**
  - Wraps: integer 0..6 (Sunday..Saturday)
  - Validation: reject out-of-range values

- **`Phases::WeekIndex`**
  - Wraps: integer ≥ 1
  - Validation: reject `< 1`

- **`Phases::WeekRange`**
  - Wraps: `Phases::WeekIndex` start + `Phases::WeekIndex` end
  - Invariant: `end >= start`

- **`Phases::LocalDate`**
  - Wraps: `Date` interpreted as a **civil calendar day** in the user’s IANA timezone context
  - Note: construction should happen at system boundaries (controllers/services) using the user’s timezone rules; the VO itself asserts non-nil `Date`

- **`Sharing::Visibility` (optional but recommended)**
  - Wraps: `private` vs `public_shareable` (public browsing + admin moderation revoke)

## Roadmap linkage
- **Roadmap item**: Phase 4 — Menus & Recipes (Alimentación) — items **15–19** (`REQ-MENU-001` … `REQ-MENU-005`)

## UX surfaces (Hotwire-first)
- **Menus index**: list menus; create/edit
- **Menu editor**: grid (7×meal_types) with Turbo-driven inline edit
- **Recipes index**: list recipes; create/edit; upload image
- **Phase setup**:
  - set phase1_start_date
  - manage week-range assignments
  - show “current week” and “active menu”
- **Phase extension prompt**: banner/modal when plan ended
- **Mi Día shortcut**: a persistent entry point below the “Mi Día” content that navigates to the menu/phase surfaces (Turbo navigation)

## Architecture notes (fit to current stack)
- Keep controllers thin; use service objects under `app/services/menus/*` and `app/services/recipes/*` and `app/services/phases/*`.
- All user-visible strings go through I18n (Spanish first).
- Prefer DB constraints for uniqueness (unique indexes) for `(menu_id, weekday, meal_type)` and for week-range non-overlap (may require validation-level + check constraints if feasible in SQLite).
- Scheduling:
  - Favor a **daily job** that checks “phases beginning today” in each user’s timezone and creates a reminder event.
  - Avoid per-user delayed jobs unless Solid Queue supports reliable scheduled runs across restarts in this repo’s posture.

## Risks / Ambiguities to resolve
- Recipe fallback image “per meal type” depends on **context** (recipe can be used by multiple meal types).
- SQLite constraints for non-overlapping ranges are limited; need a robust model validation + database best-effort.
- Moderation at scale: public sharing needs admin workflows and clear UX when content is revoked (imports/copies remain unaffected).

## Open questions (resolved / moved)
- Sharing visibility + moderation + reminder channel/dismiss decisions are captured under **Decisions (since last update)**.
- MenuEntry “recipe + note” simultaneity remains in **Backlog / deferred decisions**.

## Decisions (since last update)
- **Sharing visibility**: Shareable content is **public** (browse/search by all users).
- **Moderation**: an **admin** can revoke sharing on a recipe/menu to remove undesirable content from public browsing.
- **Reminder channels**: user configures **in-app** and **email** independently (can enable either/both/none).
- **In-app reminder dismissal**: reminders can be **dismissed for the current local day** (“dismiss for today”) to avoid re-showing.

## Backlog / deferred decisions
- Decide whether a `MenuEntry` may have **recipe + note** simultaneously vs enforce **XOR** (exactly one of recipe or freeform).
- Define behavior when user disables freeform while existing freeform entries exist (read-only vs require conversion).

<implementation_plan>
  <metadata>
    <task_name>phase-4-menus-recipes-alimentacion</task_name>
    <classification>Feature</classification>
    <requirements>
      <req id="REQ-MENU-001" />
      <req id="REQ-MENU-002" />
      <req id="REQ-MENU-003" />
      <req id="REQ-MENU-004" />
      <req id="REQ-MENU-005" />
    </requirements>
    <architecture_guardrails>
      <item>Hotwire-first, server-rendered ERB; thin controllers; service objects under app/services/.</item>
      <item>ActiveStorage for images; Solid Queue for scheduled work where needed.</item>
      <item>All user-visible strings via I18n (es default).</item>
      <item>RSpec-first; each spec example tagged with # [REQ-...] for traceability.</item>
    </architecture_guardrails>
  </metadata>

  <milestone name="0 - Spec hardening">
    <step>Confirm naming and data placement for Phase 1 start date (User column vs PhasePlan model) and document it in this file if it changes.</step>
    <step>Confirm whether MenuEntry allows recipe+note simultaneously or enforces XOR (tracked in backlog; do not block Phase 4 MVP unless required).</step>
  </milestone>

  <milestone name="1 - Data model for menus & recipes (REQ-MENU-001, REQ-MENU-002)">
    <step>Write failing model specs for Menu/Recipe/MenuEntry ownership, validations, and constraints (uniqueness per (menu, weekday, meal_type); presence rules for entry content).</step>
    <step>Implement models and migrations, including indexes and foreign keys; wire ActiveStorage attachment for Recipe image.</step>
    <step>Add policy/validation ensuring users can only access their own menus/recipes, except browsing public shared content.</step>
    <step>Write specs for sharing: shareable flag, public visibility query scope, admin moderation action (revoke sharing) behavior.</step>
  </milestone>

  <milestone name="2 - Menu editor UX (REQ-MENU-001)">
    <step>Write request/system specs for menu CRUD and the 7x4 grid editor interactions (Turbo forms), including empty slots (sparse records) behavior.</step>
    <step>Implement controllers/views with Turbo; keep orchestration in services (e.g., Menus::UpsertEntry).</step>
    <step>Implement recipe picker inside a slot and freeform text entry (guarded by per-user preference).</step>
    <step>Implement meal-type fallback image in the menu slot UI (context-based when recipe has no image).</step>
  </milestone>

  <milestone name="3 - Recipe library UX (REQ-MENU-002)">
    <step>Write system specs for recipe CRUD, image upload, and display behavior (including fallback image behavior in slot context).</step>
    <step>Implement recipes controller/views; ensure I18n coverage and consistent attachment rendering.</step>
  </milestone>

  <milestone name="4 - Phase system & week-range assignments (REQ-MENU-003)">
    <step>Write unit specs for week index calculation from user timezone + phase1_start_date (edge cases: before start date, timezone changes, boundary days).</step>
    <step>Implement phase start date persistence and services for computing current week and resolving active menu for a local date.</step>
    <step>Write model/service specs for PhaseAssignment validation (no overlaps; gaps allowed) and active assignment lookup.</step>
    <step>Implement Phase setup UI (start date + assignment CRUD) and expose “current week” + active menu.</step>
  </milestone>

  <milestone name="5 - Alerts, reminders, and extension (REQ-MENU-004, REQ-MENU-005)">
    <step>Write specs for start-date warning rule (more than 3 days in future) and for reminder preference behavior (in-app/email independent).</step>
    <step>Implement reminder event persistence (idempotent key per user + local day/week index) and a daily Solid Queue job to enqueue/send reminders due “today” in each user’s timezone.</step>
    <step>Implement in-app reminder banner with “dismiss for today” persistence; write system specs for dismissal not reappearing the same day.</step>
    <step>Implement Phase extension detection (plan ended) and prompt UI; implement “repeat last phase” and “add new range” flows with specs.</step>
  </milestone>

  <milestone name="6 - Mi Día shortcut integration">
    <step>Write system spec asserting the Mi Día page shows a shortcut below the main content and navigates to the phase/menu area.</step>
    <step>Implement the shortcut in Mi Día view (Turbo navigation).</step>
  </milestone>

  <milestone name="7 - Hardening & i18n">
    <step>Audit all new strings for I18n; ensure Spanish default copy is complete.</step>
    <step>Review DB constraints and add best-effort safeguards in SQLite; ensure queries are eager-loaded to avoid N+1 in grids.</step>
  </milestone>
</implementation_plan>

