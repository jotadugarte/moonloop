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
| `DAY` | Daily habit tracking (“Mi Día”) — **planned** |
| `MENU` | Menus & recipes — **planned** |
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

---

## Core entities and relationships

- **User** (`users`)
  - `has_many :sessions`, `has_many :habit_categories`, `has_many :user_habits`, `has_many :weight_logs`
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
| REQ-HAB-009 | `UserHabit#next_occurrence_after` delegates to `Habits::NextOccurrence` for `daily` and `monthly`; for `monthly`, if the anchor day does not exist in a month, the date **clamps** to the last valid day of that month. Other frequency types may raise until extended. | Implemented (subset of types) |
| REQ-WGT-001 | `weight_logs` persist historical weight, height snapshot, and BMI for a user. | Implemented (data model; full Phase 6 UX tracked on roadmap) |

---

## Requirement registry (planned — roadmap)

These IDs are reserved for traceability; behavior is **not** fully implemented until the corresponding phase ships.

| ID | Requirement | Roadmap phase |
|----|-------------|----------------|
| REQ-DAY-001 | “Mi Día” shows today’s **active** habits in the user’s timezone. | Phase 3 |
| REQ-DAY-002 | User marks a habit done or failed for the current day. | Phase 3 |
| REQ-DAY-003 | User can retroactively change completion for past days. | Phase 3 |
| REQ-DAY-004 | Streak per habit: consecutive completed days without failure. | Phase 3 |
| REQ-MENU-001 … REQ-MENU-005 | Weekly menu plan, recipes, phase system, alerts, extension — per roadmap Phase 4 (items 14–18). | Phase 4 |
| REQ-EXR-001 … REQ-EXR-003 | Exercise routines and linkage to “Mi Día” — per roadmap Phase 5. | Phase 5 |
| REQ-WGT-002 | Weight log UX: record entries over time (entry flow). | Phase 6 |
| REQ-WGT-003 | Weight + BMI history view (progression over time). | Phase 6 |
| REQ-RPT-001 … REQ-RPT-003 | Habit fulfillment, streak, and weight charts — per roadmap Phase 7. | Phase 7 |

---

## Key workflows (summary)

1. **Registration and verification** — User signs up → optional verification email → can complete password reset only when rules allow → sessions created on sign-in.
2. **Profile** — User maintains DOB, height, timezone, weight; BMI updated from weight and height.
3. **Habit provisioning** — On sign-in, job ensures template-backed default categories and habits exist once per logical template `code`.
4. **Category lifecycle** — CRUD categories; destroy prevented if habits still reference the category.
5. **Habit lifecycle** — Create personal habit or from template; toggle active; name collision only among active habits; frequency params validated by type.
6. **Next occurrence (preview)** — For scheduling previews/tests, daily and monthly next dates are computed via service; monthly respects shorter months.

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
