# Project Specification (SPEC.md)

This document is the **source of truth for named requirements** in Moonloop. Tests and roadmap items may reference these IDs as `[REQ-ID]`.

**REQ-ID format:** `REQ-[DOMAIN]-[NNN]` (zero-padded three digits). Domains used today:

| Domain | Scope |
|--------|--------|
| `PLAT` | Stack, runtime, conventions |
| `AUTH` | Registration, session, email verification, password reset |
| `PROF` | User profile, BMI / weight on profile |
| `HAB` | Habit templates, categories, user habits, provisioning, scheduling helpers |
| `WGT` | Weight log persistence (model-level; full UX may be later phase) |
| `I18N` | Locales and user-visible copy |
| `DAY` | Daily habit tracking (“Mi Día”) — **implemented** (Phase 3) |
| `MENU` | Menus, recipes, phase plan — **implemented** (Phase 4) |
| `EXR` | Exercise routines — **implemented** (Phase 5; acceptance criteria below) |
| `RPT` | Reporting — **planned** |

---

## Purpose and vision

Moonloop is a **wellness and habits** web application. Users authenticate, maintain a **metric profile** (height, weight, timezone, derived BMI), define **habits** grouped in **categories**, and (in later phases) track completion by day, plan meals, log weight over time, and view reports. The product is **Spanish-first** in the UI; English is supported as a secondary locale.

---

## Domain glossary

| Term | Definition | In code / UI |
|------|------------|----------------|
| User | Account with email, password, verified flag, profile fields | `User` |
| Session | Server-side login record tied to user; stores user agent and IP on create | `Session`, `cookies.signed[:session_token]` |
| Current session context | Request-scoped access to the logged-in session | `Current.session`, `ApplicationController#authenticate` |
| Habit category | User-owned label grouping habits; names unique per user (case-insensitive) | `HabitCategory` |
| Global habit template | System-wide template identified by stable `code`; used to provision default habits | `GlobalHabitTemplate` |
| User habit | A habit instance owned by a user in a category, with frequency and optional link to a template | `UserHabit` |
| Frequency type | Schedule kind: `daily`, `weekdays`, `every_x_days`, `monthly`. There is no `weekly` type: “once per week on day D” is stored as `weekdays` with `frequency_params["weekdays"]` containing a single integer 0–6. | `user_habits.frequency_type` |
| Frequency params | JSON parameters for the frequency (e.g. weekday list, interval) | `user_habits.frequency_params` |
| Active habit | Habit with `active: true`; inactive habits do not consume the “unique name among active” rule | `user_habits.active` |
| Provisioning | Idempotent job that ensures default templates/categories/habits exist for a user | `ProvisionDefaultHabitsJob`, sign-in hook |
| Weight log | Historical weight entry with snapshot height and BMI | `WeightLog` |
| Local calendar day (user) | A civil date interpreted in the user’s **current** IANA `timezone` (not `Date.current` alone for UX). | Used when resolving “today” and completion dates |
| Due day | A calendar day on which a **habit** is expected per `frequency_type`, `frequency_params`, and `activation_date`; inactive habits are never due. | `Habits::DueOnDate` (or equivalent) |
| Habit completion | At most one persisted row per `(user_habit, local calendar day)` with status **done** or **failed**; **pending** means no row (or row removed). | `HabitCompletion` / `habit_completions` |
| Streak (habit) | Count of consecutive **closed** due days ending at a reference day where the habit was **done**; a closed due day without **done** breaks the streak (explicit **failed** and absent completion are equivalent for this rule). | Derived; see REQ-DAY-004 |
| Menu | User-owned reusable **weekly** meal plan; sparse `menu_entries` for filled slots only. | `Menu` |
| Menu entry | At most one row per `(menu, weekday, meal_type)`; references optional `Recipe` and/or `freeform_text` when the user allows freeform in profile. | `MenuEntry` |
| Recipe | User-owned dish with name, instructions, optional **ActiveStorage** image; may be marked publicly shareable for catalog browsing. | `Recipe` |
| Phase 1 anchor | Civil date when the user’s program “week 1” begins; interpreted in the user’s timezone for week index math. | `users.phase_one_starts_on` |
| Program week index | Integer ≥ 1: `floor((local_date − anchor) / 7) + 1` for `local_date ≥ anchor`; `nil` before anchor. | `Phases::WeekNumber` |
| Phase assignment | Contiguous inclusive week range `[start_week..end_week]` mapped to one `Menu` per user; ranges must not overlap (gaps allowed). | `PhaseAssignment` |
| Exercise routine | User-owned reusable **weekly** exercise plan; **not** valid if totally empty across the week (see REQ-EXR-001). Display name uniqueness per user matches **menus** (normalized name, same collision rules as `Menu`). | `ExerciseRoutine` (name may match implementation) |
| Exercise routine assignment | Same shape as phase assignment: maps `[start_week..end_week]` to one exercise routine **for that user**; ranges must not overlap with **other routine assignments** (gaps allowed). Independent from menu `phase_assignments`. **CRUD UI** lives on the **phase plan** screen (`/phase`): same program as menus/fases (product decision). | TBD table name (e.g. `exercise_routine_assignments`) |
| Exercise routine line | One **ordered** line in the list for a given `(routine, weekday)`; `position` defines order within that day. Weekday 0–6 (Sunday..Saturday), aligned with menu weekday convention. A weekday may have zero lines **only if** the routine still has ≥1 line somewhere else (routine not globally empty). | TBD model name |
| Phase reminder event | Idempotent record that a phase-start reminder was processed for a given **local** calendar day and channel kind. | `PhaseReminderEvent` |

---

## Core entities and relationships

- **User** (`users`)
  - `has_many :sessions`, `has_many :habit_categories`, `has_many :user_habits`, `has_many :weight_logs`, `has_many :menus`, `has_many :recipes`, `has_many :phase_assignments`, `has_many :phase_reminder_events`; Phase 5 adds `has_many` exercise routines and routine week-range assignments (exact names per schema)
  - Authentication: `has_secure_password`; email normalized (strip, downcase)
  - Profile: `date_of_birth`, `height_cm` (readonly after set in rules), `timezone`, `current_weight_kg`, `current_bmi`, `verified`, `allow_menu_freeform` (gates freeform text on menu slots)
  - Phase plan: `phase_one_starts_on` (nullable until configured); `phase_reminder_in_app`, `phase_reminder_email` (independent channel toggles); `phase_reminder_dismissed_on` (suppresses in-app banner for that local day)

- **Session** (`sessions`)
  - `belongs_to :user`
  - Captures `user_agent` and `ip_address` on create from `Current`

- **HabitCategory** (`habit_categories`)
  - `belongs_to :user`, `has_many :user_habits`
  - Uniqueness of `name_normalized` scoped to `user_id`
  - Destroy blocked while any `user_habits` exist

- **GlobalHabitTemplate** (`global_habit_templates`)
  - `has_many :user_habits` (optional link from habit)
  - Unique `code` (normalized)

- **UserHabit** (`user_habits`)
  - `belongs_to :user`, `belongs_to :habit_category`, `belongs_to :global_habit_template` (optional)
  - `frequency_type`, `frequency_params` (JSON), `activation_date` where required by type
  - Partial unique index: among **active** rows, `(user_id, name_normalized)` unique
  - **`activation_date` edits:** may change only while the habit has **zero** completion rows; if any completion exists, changing `activation_date` is forbidden until all completions are removed (including after a user clears every day back to pending).

- **WeightLog** (`weight_logs`)
  - `belongs_to :user`; stores `weight_kg`, `height_cm`, `bmi` per entry

- **Menu** (`menus`)
  - `belongs_to :user`, `has_many :menu_entries`, `has_many :phase_assignments`
  - `publicly_shareable` for public catalog; admin may revoke sharing (moderation)

- **MenuEntry** (`menu_entries`)
  - `belongs_to :menu`, optional `belongs_to :recipe`
  - Unique `(menu_id, weekday, meal_type)`; `weekday` 0–6 (Sunday..Saturday); `meal_type` one of the canonical habit-aligned keys (`desayuno`, `almuerzo`, `cena`, `merienda`)
  - Content: at least one of `recipe_id` or `freeform_text` when persisted (subject to user preference)

- **Recipe** (`recipes`)
  - `belongs_to :user`, `has_many :menu_entries`; optional `has_one_attached :image`
  - `publicly_shareable`; admin may revoke sharing

- **PhaseAssignment** (`phase_assignments`)
  - `belongs_to :user`, `belongs_to :menu`; `start_week`, `end_week` with DB check constraints (`start_week ≥ 1`, `end_week ≥ start_week`)
  - Non-overlapping week ranges per user enforced in the model

- **PhaseReminderEvent** (`phase_reminder_events`)
  - `belongs_to :user`; unique `(user_id, kind, local_date)` for idempotent reminder delivery

---

## Requirement registry (implemented)

| ID | Requirement | Status |
|----|-------------|--------|
| REQ-PLAT-001 | Application uses Rails 8.x with SQLite, Propshaft, importmap-rails, Turbo, and Stimulus as the default stack. | Implemented |
| REQ-I18N-001 | User-facing copy uses I18n; default locale Spanish (`:es`), English (`:en`) available. | Implemented |
| REQ-AUTH-001 | User can register with email and password; email format and uniqueness enforced; password minimum length enforced. | Implemented |
| REQ-AUTH-002 | User can sign in with email and password; invalid credentials are rejected without distinguishing which field failed inappropriately. | Implemented |
| REQ-AUTH-003 | Authenticated browser access requires a valid signed session cookie mapping to a `Session` record; otherwise redirect to sign-in. | Implemented |
| REQ-AUTH-004 | User can sign out; session is destroyed. | Implemented |
| REQ-AUTH-005 | Email verification flow uses time-limited signed tokens; invalid links are handled. | Implemented |
| REQ-AUTH-006 | Password reset via email; unverified users cannot reset password until email is verified (per product rules). | Implemented |
| REQ-AUTH-007 | When password changes, sessions other than the current one are invalidated. | Implemented |
| REQ-PROF-001 | Profile enforces presence and validity of `date_of_birth`, `height_cm`, and `timezone` (IANA name set). | Implemented |
| REQ-PROF-002 | User stores `current_weight_kg` and `current_bmi`; BMI is derived from weight and height per application rules. | Implemented |
| REQ-HAB-001 | System stores `global_habit_templates` with unique stable `code` values. | Implemented |
| REQ-HAB-002 | After sign-in, provisioning runs so each user gains default categories and habits from templates **idempotently** (safe to repeat). | Implemented |
| REQ-HAB-003 | User can create, update, and delete habit categories; names are unique per user ignoring case; category delete is forbidden if habits reference it. | Implemented |
| REQ-HAB-004 | Each `user_habit` belongs to exactly one user and one category; may reference a global template. | Implemented |
| REQ-HAB-005 | `frequency_type` must be one of: `daily`, `weekdays`, `every_x_days`, `monthly`. `frequency_params` is validated as a JSON object; for `weekdays`, a non-empty array of integers 0–6 (exactly one element encodes “once per week on that weekday”); interval ≥ 1 for `every_x_days`; `activation_date` required where the model enforces it (including `monthly` and `every_x_days`). Any legacy `weekly` rows are migrated to `weekdays` with a one-element `weekdays` array. | Implemented |
| REQ-HAB-006 | Among **active** habits, display name uniqueness per user is enforced using normalized name (case-insensitive). | Implemented |
| REQ-HAB-007 | User can activate and deactivate habits, including defaults; deactivated habits can be reactivated. | Implemented |
| REQ-HAB-008 | UI lists habits grouped by category; user can create a personal habit and add a habit from a template. | Implemented |
| REQ-HAB-009 | `UserHabit#next_occurrence_after` delegates to `Habits::NextOccurrence` for `daily`, `weekdays`, `every_x_days`, and `monthly`. For `monthly`, if the anchor day does not exist in a month, the date **clamps** to the last valid day of that month. `weekdays` and `every_x_days` follow the same calendar rules as `Habits::DueOnDate`. | Implemented |
| REQ-DAY-001 | “Mi Día” lists **active** habits that are **due** on the selected calendar day, resolved using the user’s **current** timezone. Inactive habits are omitted. For a given day, habits are not listed for dates **before** `activation_date`. A habit due that day stays visible **unmarked** while still pending (clearing completion does not hide the row). | Implemented |
| REQ-DAY-002 | User marks a habit **done** or **failed** for a calendar day (at least the current day); persistence is per local day and habit. | Implemented |
| REQ-DAY-003 | User may change completion **retroactively** for any **past** local day (no upper bound); **future** days cannot be marked. User may switch between done, failed, and **pending** (pending = no completion row). | Implemented |
| REQ-DAY-004 | **Streak** per habit: longest run of consecutive **due** days where each day is **done**, evaluated only on **closed** days (before “today” in the user’s TZ, the streak does not treat an open today as a failure). A closed due day without **done** breaks the streak (**failed** and absent row are equivalent for streak). Reactivation keeps existing completion history. | Implemented |
| REQ-WGT-001 | `weight_logs` persist historical weight, height snapshot, and BMI for a user. | Implemented (data model; full Phase 6 UX tracked on roadmap) |
| REQ-MENU-001 | Weekly **menu** plan: at most one persisted slot per `(menu, weekday, meal_type)`; slot holds a user-owned **recipe** and/or optional freeform text per profile preference; validations and Hotwire grid editor. | Implemented |
| REQ-MENU-002 | **Recipe** model: name, instructions, optional **ActiveStorage** image; in menu slots, fallback image by meal type when the recipe has no image. | Implemented |
| REQ-MENU-003 | **Phase** anchor `phase_one_starts_on` on user; program **week index** from anchor and user timezone; **phase_assignments** map contiguous week ranges to menus (no overlaps); active menu resolution for current week. | Implemented |
| REQ-MENU-004 | If anchor is more than three **local** days away, flash warning; **reminder** on phase-start day: in-app banner (dismiss for today) and optional email; independent channel prefs; idempotent `phase_reminder_events` and daily sweep job (`config/recurring.yml`). | Implemented |
| REQ-MENU-005 | When current week is **past** all assignment ranges, show extension prompt; **repeat last block** (same menu and span) or link to **add a new range**. | Implemented |
| REQ-EXR-001 | **Exercise routine content model:** user-owned weekly routine; ordered lines per weekday (0–6); CRUD + duplicate; delete with cascade of week-range assignments after confirmation. See **Acceptance criteria — REQ-EXR-001** below. | Implemented |
| REQ-EXR-002 | **Program weeks → routine:** same anchor and `Phases::WeekNumber` as menus; `exercise_routine_assignments` with non-overlapping ranges per user; resolve active routine; phase plan UI on `/phase`. See **Acceptance criteria — REQ-EXR-002** below. | Implemented |
| REQ-EXR-003 | **Mi Día + navigation:** active routine context for **`fitness_exercise`** when due; global shortcuts; home and plan entry points. See **Acceptance criteria — REQ-EXR-003** below. | Implemented |
| REQ-EXR-004 | **Phase alerts (routine lane):** shared anchor warning; phase-start reminders coherent with menus; routine lane visible on `/phase`. See **Acceptance criteria — REQ-EXR-004** below. | Implemented |
| REQ-EXR-005 | **Routine plan extension:** when current week is past all routine ranges, extension prompt; repeat last routine block or add new range. See **Acceptance criteria — REQ-EXR-005** below. | Implemented |

---

## Requirement registry (planned — roadmap)

These IDs are reserved for traceability; behavior is **not** fully implemented until the corresponding phase ships.

| ID | Requirement | Roadmap phase |
|----|-------------|----------------|
| REQ-WGT-002 | Weight log UX: record entries over time (entry flow). | Phase 6 |
| REQ-WGT-003 | Weight + BMI history view (progression over time). | Phase 6 |
| REQ-RPT-001 … REQ-RPT-003 | Habit fulfillment, streak, and weight charts — per roadmap Phase 7. | Phase 7 |

### Scheduling — due-day resolution (Mi Día)

These rules define whether a habit is **due** on a given **local** calendar day for the user. They align with `REQ-HAB-005` frequency types (no `weekly`; single weekday uses `weekdays` with one element).

- **`daily`** — Due on every local calendar day **on or after** the habit’s effective start date (`activation_date` when set; when unset, a defined fallback such as the habit’s `created_at` converted to the user’s local date — see implementation).
- **`weekdays`** — Due on listed weekdays (0 = Sunday … 6 = Saturday). The **first** due day is the first matching weekday **on or after** `activation_date`.
- **`every_x_days`** — `activation_date` is the **first** due day; thereafter due when `(local_date - activation_date) % interval == 0` (civil days in the user’s timezone). Not due on any local date **before** `activation_date`.
- **`monthly`** — Due on the anchor day-of-month from `activation_date`, with **end-of-month clamp** when the anchor does not exist in a month (same idea as `REQ-HAB-009` for `NextOccurrence`). The calendar month that contains `activation_date` counts toward scheduling.

### Acceptance criteria — exercise routines (Phase 5)

These criteria are **testable**; implementation may use different model/table names if behavior matches. **Product decisions** for Phase 5 are locked in **Decisions log — REQ-EXR** below.

#### REQ-EXR-001 — Weekly routine content

1. An authenticated user can **create** a named exercise routine owned by themselves; **name** is required, normalized (strip whitespace), and **unique per user** in the same sense as **`Menu`** (case-insensitive / normalized uniqueness — mirror `menus` rules).
2. For each **weekday** 0–6, planned content is an **ordered list** of lines (each line is a persisted row with **`position`** ordering within that weekday). Lines may include a primary label and optional notes per implementation; **individual weekdays may have zero lines** as long as the routine is not globally empty (see (3)).
3. A routine is **invalid to save** if it would be **totally empty**: there must be **at least one line item** on **at least one** weekday (validation error on create/update).
4. **Performance / limits:** use **reasonable defaults** aligned with normal Rails + SQLite usage (e.g. sensible string length per line, optional cap on lines per day to prevent abuse); exact numbers live in implementation and migrations but must not allow pathological payloads.
5. The user can **list** all their routines, **edit** a routine, **delete** a routine, and **duplicate** an existing routine into a **new** routine (new name, copy of structure/content), same-owner only. **Delete with assignments (Q12):** deletion **is allowed**; before committing, the UI shows a **warning** that **all week-range assignments** referencing this routine will be **removed automatically**; on confirmation, the system deletes those assignment rows **then** the routine (single logical operation, transactional).
6. All user-visible strings use I18n (`es` default, `en` available).
7. Authorization: a user cannot read or mutate another user’s routines (scoped by `Current.user` or equivalent).

#### REQ-EXR-002 — Week ranges → routine (same system as menus)

1. **Same anchor:** program week index for routines uses **`users.phase_one_starts_on`** and the user’s **current** IANA timezone, via the same week-index semantics as **`Phases::WeekNumber`** (and the same “no index before anchor” rule as menus).
2. **Assignments:** the user can define one or more **contiguous inclusive** ranges `[start_week, end_week]` (integers ≥ 1, `end_week ≥ start_week`) each pointing to **one** of their exercise routines; **ranges must not overlap** with each other for that user’s **routine** assignments (gaps between ranges are allowed).
3. **Independence:** routine week assignments do **not** share a table with menu `phase_assignments` and do **not** participate in menu overlap validation; the same week index may resolve to both an active menu and an active exercise routine.
4. **Resolve active routine:** given a `week_index` (or derived from a local date), the system can resolve **zero or one** active routine for that user (first matching range in a deterministic order, e.g. ascending `start_week`, mirroring menu resolution).
5. Validations mirror `PhaseAssignment` quality bar: self-overlap on create/update must not false-positive unsaved records (DB-scoped overlap check).
6. **Phase plan surface:** CRUD for **routine week-range assignments** uses the **same phase plan UX** as menu assignments — i.e. integrated on **`GET /phase`** (or the same “phase” flow the app uses for `phase_assignments`), not a separate standalone assignment app.

#### REQ-EXR-003 — Mi Día linkage and shortcuts

1. **Habit row (Ejercicio):** When the user’s `UserHabit` for **`fitness_exercise`** exists **and** is **due** on the selected Mi Día date per `REQ-DAY-001`, the UI shows the **active routine** context for that week (preview / links). Identification is by **`GlobalHabitTemplate#code == "fitness_exercise"`**, not display name.
2. **Only when the habit is due:** the **inline** routine preview / habit-row integration appears **only** on days when Ejercicio is in the due list (not on days when it is not due).
3. **Global shortcut:** Mi Día always exposes a **global** Turbo-friendly shortcut to the exercise routine / phase plan entry points (same family as `data-test="my-day-phases-shortcut"`), **even if** the user has **no** `fitness_exercise` habit row (deleted template, etc.).
4. **Inactive Ejercicio habit:** if the `fitness_exercise` habit exists but is **inactive**, show the routine-related UI in a **disabled** state that explains reactivation (encourage the user to turn the habit back on); do not pretend the habit is active.
5. **Preview + week:** Mi Día shows what applies to **that calendar day** within the active routine **and** provides a link to view the **full week** layout for the active routine when relevant.
6. **Turbo:** links use patterns consistent with existing shortcuts (`turbo_action: "advance"` where appropriate).
7. **Navigation beyond Mi Día:** the user can reach exercise routine management and the phase plan from **home** (or primary nav), not only from Mi Día.
8. There is a discoverable path from the routine/plan area back to Mi Día (navigation symmetry with menus/phases as far as layout allows).

#### REQ-EXR-004 — Phase alerts (parity REQ-MENU-004, routine lane)

1. **Shared anchor:** The same **`phase_one_starts_on`** rules as **REQ-MENU-003** / **REQ-MENU-004** apply to the overall program (one anchor for both menu and routine week math).
2. **Warning:** If the user sets or changes the anchor to more than **three local days** in the future, show the same class of **flash warning** as for menus (REQ-MENU-004).
3. **Reminders:** Phase-start **in-app** and **email** behavior (REQ-MENU-004) must remain coherent when the user has **routine** assignments: the `/phase` experience makes the **routine** lane visible alongside the menu lane so the user does not rely only on menu rows to understand the program. (Reuse existing reminder jobs/events where possible; extend copy or sections only as needed so routines are not omitted.)

#### REQ-EXR-005 — Routine plan extension (parity REQ-MENU-005)

1. **Plan ended (routines only):** When the current **program week index** is **greater than** the maximum `end_week` among the user’s **exercise routine week-range assignments** (and at least one assignment exists), treat the **routine** plan as ended — mirror **REQ-MENU-005** semantics for the menu lane (`Phases::PlanEnded` pattern).
2. **Prompt:** Show an extension prompt for the **routine** lane: user can **repeat the last contiguous routine assignment block** (same routine and span as the last block) or **add a new week range** mapped to a routine.
3. **Service parity:** Implement the analogue of **`Phases::RepeatLastPhaseAssignment`** for routine assignments (new service under `ExerciseRoutines::` or `Phases::`, consistent with SYSTEM_ARCHITECTURE).

#### Decisions log — REQ-EXR (Phase 5, locked)

| ID | Decision |
|----|----------|
| Q1 | Content per weekday: **ordered list** of lines with `position`. |
| Q2 | **No** routine may be saved **completely empty** (≥1 line on ≥1 weekday). |
| Q3 | Lengths/counts: **reasonable implementation limits** (standard Rails/SQLite practice); no arbitrary product number required in SPEC. |
| Q4 | **Global shortcut** to routines/plan always on Mi Día even without `fitness_exercise` habit. |
| Q5 | **Inline** habit-row integration **only when Ejercicio is due** that day. |
| Q6 | If Ejercicio exists but is **inactive**: show routine block **disabled** + message to reactivate. |
| Q7 | Routine **week-range assignments** are edited on the **phase plan** (`/phase` family), alongside menu phase assignments. |
| Q8 | **Public sharing** of routines (like menus/recipes): **not** Phase 5 — see **Backlog** in `docs/ROADMAP.md`. |
| Q9 | **Reuse** existing phase-assignment UX for routine ranges. |
| Q10 | Mi Día: day preview **plus** link to **full week** view for the active routine. |
| Q11 | **Parity with menus:** **REQ-MENU-004**-style alerts/reminders and **REQ-MENU-005**-style plan-ended extension apply to the **routine** lane — see **REQ-EXR-004** and **REQ-EXR-005**. |
| Q12 | **Delete routine** when week-range assignments exist: **allowed**; user sees a **prior warning** that assignments will be **removed automatically**; on confirm, system **deletes those ranges then the routine** (transactional). |
| Q13 | Routine **name uniqueness** per user: **same rules as `Menu`**. |
| Q14 | User can **duplicate** a routine (copy) into a new owned routine. |
| Q15 | Entry points from **home** / primary navigation, not only Mi Día. |

---

## Key workflows (summary)

1. **Registration and verification** — User signs up → optional verification email → can complete password reset only when rules allow → sessions created on sign-in.
2. **Profile** — User maintains DOB, height, timezone, weight; BMI updated from weight and height.
3. **Habit provisioning** — On sign-in, job ensures template-backed default categories and habits exist once per logical template `code`.
4. **Category lifecycle** — CRUD categories; destroy prevented if habits still reference the category.
5. **Habit lifecycle** — Create personal habit or from template; toggle active; name collision only among active habits; frequency params validated by type.
6. **Next occurrence (preview)** — For scheduling previews/tests, `Habits::NextOccurrence` implements the same frequency types as Mi Día scheduling (`daily`, `weekdays`, `every_x_days`, `monthly`), aligned with `Habits::DueOnDate` where applicable. Monthly respects shorter months (end-of-month clamp).

---

## Implementation deep dive

Feature-specific docs can be linked here as they are written, for example:

- Habits core: models under `app/models/user_habit.rb`, `habit_category.rb`, `global_habit_template.rb`; services under `app/services/habits/`
- Provisioning: `ProvisionDefaultHabitsJob` and sign-in integration
- Phase 4 (Alimentación): `Menu`, `MenuEntry`, `Recipe`, `PhaseAssignment`, `PhaseReminderEvent`; services under `app/services/menus/` and `app/services/phases/`; Turbo menu grid under `Menus::MenuEntriesController`; Solid Queue job `Phases::SweepPhaseStartRemindersJob` (see `config/recurring.yml`); admin moderation under `Admin::*` gated by `MOONLOOP_ADMIN_EMAILS`
- Phase 5 (Rutinas de ejercicio): models `ExerciseRoutine`, `ExerciseRoutineLine`, `ExerciseRoutineAssignment`; services under `app/services/exercise_routines/`; `ExerciseRoutinesController`, `ExerciseRoutineAssignmentsController`; Mi Día (`MyDayController`) + `/phase` integration; parity **REQ-EXR-004** / **REQ-EXR-005** with **REQ-MENU-004** / **REQ-MENU-005**. See **Acceptance criteria — exercise routines (Phase 5)** and **Decisions log — REQ-EXR** in this file.

---

## Traceability in tests

**Project convention** (enforced for agents via Cursor rules):

- `.cursor/rules/spec-req-traceability.mdc` — comments in `spec/**/*_spec.rb`
- `.cursor/rules/spec-md-req-registry.mdc` — when editing this file (`SPEC.md`)

Place the tag **immediately above** each `it` / `specify` (including one-line Shoulda examples):

```ruby
# [REQ-HAB-006]
it "does not allow two active habits with the same normalized name" do
  # ...
end
```

Use IDs from the registries above only. If one example covers two distinct requirements, use a single comment with comma-separated IDs in **alphabetical order** by ID, for example `# [REQ-AUTH-002, REQ-HAB-002]`.
