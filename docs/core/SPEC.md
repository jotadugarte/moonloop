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
| `EXR` | Exercise routines — **planned** |
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

---

## Core entities and relationships

- **User** (`users`)
  - `has_many :sessions`, `has_many :habit_categories`, `has_many :user_habits`, `has_many :weight_logs`, `has_many :menus`, `has_many :recipes`, `has_many :phase_assignments`, `has_many :phase_reminder_events`
  - Authentication: `has_secure_password`; email normalized (strip, downcase)
  - Profile: `date_of_birth`, `height_cm` (readonly after set in rules), `timezone`, `current_weight_kg`, `current_bmi`, `verified`

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

---

## Requirement registry (planned — roadmap)

These IDs are reserved for traceability; behavior is **not** fully implemented until the corresponding phase ships.

| ID | Requirement | Roadmap phase |
|----|-------------|----------------|
| REQ-EXR-001 … REQ-EXR-003 | Exercise routines and linkage to “Mi Día” — per roadmap Phase 5. | Phase 5 |
| REQ-WGT-002 | Weight log UX: record entries over time (entry flow). | Phase 6 |
| REQ-WGT-003 | Weight + BMI history view (progression over time). | Phase 6 |
| REQ-RPT-001 … REQ-RPT-003 | Habit fulfillment, streak, and weight charts — per roadmap Phase 7. | Phase 7 |

### Scheduling — due-day resolution (Mi Día)

These rules define whether a habit is **due** on a given **local** calendar day for the user. They align with `REQ-HAB-005` frequency types (no `weekly`; single weekday uses `weekdays` with one element).

- **`daily`** — Due on every local calendar day **on or after** the habit’s effective start date (`activation_date` when set; when unset, a defined fallback such as the habit’s `created_at` converted to the user’s local date — see implementation).
- **`weekdays`** — Due on listed weekdays (0 = Sunday … 6 = Saturday). The **first** due day is the first matching weekday **on or after** `activation_date`.
- **`every_x_days`** — `activation_date` is the **first** due day; thereafter due when `(local_date - activation_date) % interval == 0` (civil days in the user’s timezone). Not due on any local date **before** `activation_date`.
- **`monthly`** — Due on the anchor day-of-month from `activation_date`, with **end-of-month clamp** when the anchor does not exist in a month (same idea as `REQ-HAB-009` for `NextOccurrence`). The calendar month that contains `activation_date` counts toward scheduling.

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
