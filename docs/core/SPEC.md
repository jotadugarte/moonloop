# Project Specification (SPEC.md)

This document is the **source of truth for named requirements** in Moonloop. Tests and roadmap items may reference these IDs as `[REQ-ID]`.

**REQ-ID format:** `REQ-[DOMAIN]-[NNN]` (zero-padded three digits). Domains used today:

| Domain | Scope |
|--------|--------|
| `PLAT` | Stack, runtime, conventions |
| `AUTH` | Registration, session, email verification, password reset |
| `PROF` | User profile, BMI / weight on profile |
| `HAB` | Habit templates, categories, user habits, provisioning, scheduling helpers |
| `WGT` | Weight log — persistence, entry flow, history, reconciliation, UI units (`REQ-WGT-001`–`004`) |
| `I18N` | Locales and user-visible copy |
| `DAY` | Daily habit tracking (“Mi Día”) — **implemented** (Phase 3) |
| `MENU` | Menus, recipes, phase plan — **implemented** (Phase 4) |
| `EXR` | Exercise routines — **implemented** (Phase 5; acceptance criteria below) |
| `RPT` | Reporting (Informes) — **implemented** (Phase 7) |
| `CAT` | Public authenticated **catalogs** (menus, routines, phase programs): adoption **metrics**, **sort by popularity**, optional **discovery** facets and filters — **implemented** (`REQ-CAT-001`) |
| `PHS` | Unified **phase programs** (bundles): menus + routines under one shareable program — **implemented** (`REQ-PHS-001`) |

---

## Purpose and vision

Moonloop is a **wellness and habits** web application. Users authenticate, maintain a **metric profile** (height, weight, timezone, derived BMI), define **habits** grouped in **categories**, track completion by day, plan meals, **log weight over time** with history, and view **aggregate reports** (fulfillment, streaks, weight trend) on **Informes** (`GET /informes`). The product is **Spanish-first** in the UI; English is supported as a secondary locale.

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
| Weight log | Historical weigh-in: **`logged_at`** (product timeline, UTC in DB), **`weight_kg`**, snapshot **`height_cm`**, derived **`bmi`**; entry form, history list, delete + reconcile | `WeightLog` |
| Body unit system | User preference **`metric`** (kg/cm in UI) or **`imperial_us`** (lb, ft/in in UI). Canonical storage is always **`weight_kg`** / **`height_cm`**; conversion for display and form parsing uses **`BodyMetrics`** (**REQ-PROF-003**). | `users.body_unit_system` |
| Date of birth (form) | Collected as **`user[birth_year]`**, **`user[birth_month]`**, **`user[birth_day]`** on registration and profile edit; **`BirthDateTriplet`** builds a calendar **`Date`**, or **`:incomplete`** (any blank → stored **`date_of_birth`** nil where permitted) or **`:invalid`** (impossible day → **`date_of_birth`** validation **`invalid_calendar`**, no bogus date persisted). Stimulus **`birth_date_controller.js`** coordinates the three controls in the shared partial **`shared/_birth_date_fields`**. | `RegistrationsController`, `ProfilesController`, `app/controllers/concerns/birth_date_triplet.rb` |
| Local calendar day (user) | A civil date interpreted in the user’s **current** IANA `timezone` (not `Date.current` alone for UX). | Used when resolving “today” and completion dates |
| Due day | A calendar day on which a **habit** is expected per `frequency_type`, `frequency_params`, and `activation_date`; inactive habits are never due. | `Habits::DueOnDate` (or equivalent) |
| Habit metric kind | Classifies how progress is measured for a **`UserHabit`**: **`none`** (binary: only done/failed semantics as before), **`count`** (discrete units, e.g. glasses), or **`duration_min`** (whole minutes). Closed vocabulary; Mi Día, streaks, and reports use the same definitions (see **REQ-DAY-005**). | `user_habits` (persisted column; exact name per schema) |
| Daily target (habit) | Positive integer goal for the local day when **habit metric kind** is not **`none`**; user-**editable**; **suggested default** may be copied from **`GlobalHabitTemplate`** at provision time. For **`none`** habits the canonical stored target is **1** or omitted per schema—UI does not expose a quantity. | `user_habits` (persisted column; exact name per schema) |
| Day progress (habit completion) | Non-negative integer **accumulated** for that user-local calendar day on the **single** `HabitCompletion` row when one exists; multiple UI increments update this running total. Bounded by product validation (same upper bound family as **daily target**). | `habit_completions` (persisted column; exact name per schema) |
| Habit completion | At most one persisted row per `(user_habit, local calendar day)` with status **done** or **failed**; **pending** means no row (or row removed). For habits with a non-**`none`** **habit metric kind**, the row also stores **day progress** toward the **daily target**; **`marked_failed_by_user`** distinguishes the user’s **explicit failure** from **`status` = failed** that only reflects “below target / not fulfilled yet” so Mi Día can label partial progress without implying intentional failure. **Explicit failed** still means the day is **not** fulfilled for streaks and reports even if progress is partial. Otherwise the day counts as **done** for streaks and reports when **day progress** ≥ **daily target**; persisted **`status`** stays **in sync** with those rules so **`Habits::Streak`**, **`Habits::MiDayStreakPrefetch`**, and reporting share one definition (**REQ-DAY-005**). | `HabitCompletion` / `habit_completions` |
| Streak (habit) | Count of consecutive **closed** due days ending at a reference day where the habit was **done**; a closed due day without **done** breaks the streak (explicit **failed** and absent completion are equivalent for this rule). | Derived; see REQ-DAY-004 |
| Menu | User-owned reusable **weekly** meal plan; sparse `menu_entries` for filled slots only. | `Menu` |
| Menu entry | At most one row per `(menu, weekday, meal_type)`; references optional `Recipe` and/or `freeform_text` when the user allows freeform in profile. | `MenuEntry` |
| Recipe | User-owned dish with name, instructions, optional **ActiveStorage** image; may be marked publicly shareable for catalog browsing. | `Recipe` |
| Phase 1 anchor | Civil date when the user’s program “week 1” begins; interpreted in the user’s timezone for week index math. | `users.phase_one_starts_on` |
| Program week index | Integer ≥ 1: `floor((local_date − anchor) / 7) + 1` for `local_date ≥ anchor`; `nil` before anchor. | `Phases::WeekNumber` |
| Phase assignment | Contiguous inclusive week range `[start_week..end_week]` mapped to one `Menu` per user; ranges must not overlap (gaps allowed). | `PhaseAssignment` |
| Phase program (bundle) | User-owned **named** template that **groups** coordinated menu and exercise routine planning for program weeks under **REQ-PHS-001**; optional public catalog and adopted-copy metadata (fingerprint, origin) in parity with menus and exercise routines. | `PhaseProgram` |
| Phase program assignment | One row per **contiguous program week range** inside a **`PhaseProgram`**, binding one **`Menu`** and one **`ExerciseRoutine`** owned by the same user; ranges **must not overlap** with other rows of the **same** program (orthogonal to global `phase_assignments` / `exercise_routine_assignments`). | `PhaseProgramAssignment` |
| Exercise routine | User-owned reusable **weekly** exercise plan; **not** valid if totally empty across the week (see REQ-EXR-001). Display name uniqueness per user matches **menus** (normalized name, same collision rules as `Menu`). Optional **`publicly_shareable`** public catalog (REQ-EXR-006); adopted copies may reference a **source** routine with explicit content sync. | `ExerciseRoutine` (name may match implementation) |
| Exercise routine assignment | Same shape as phase assignment: maps `[start_week..end_week]` to one exercise routine **for that user**; ranges must not overlap with **other routine assignments** (gaps allowed). Independent from menu `phase_assignments`. **CRUD UI** lives on the **phase plan** screen (`/phase`): same program as menus/fases (product decision). | `exercise_routine_assignments` |
| Exercise routine line | One **ordered** line in the list for a given `(routine, weekday)`; `position` defines order within that day. Weekday 0–6 (Sunday..Saturday), aligned with menu weekday convention. A weekday may have zero lines **only if** the routine still has ≥1 line somewhere else (routine not globally empty). | `exercise_routine_lines` |
| Phase reminder event | Idempotent record that a phase-start reminder was processed for a given **local** calendar day and channel kind. | `PhaseReminderEvent` |
| Habit reminder (per habit) | Optional daily reminder for an **active** `UserHabit` at a fixed **local time-of-day** in the user’s IANA timezone, with independent channel toggles (**email** / **web push**). MVP schedules **one** firing per habit per local day (job matches `HH:MM` in the user zone). | `UserHabit` reminder columns; `Habits::SweepHabitRemindersJob` |
| Habit reminder event | Idempotent bookkeeping that the per-habit reminder pipeline ran for `(user, user_habit, local_date)` — it prevents duplicate processing on retries; it does **not** assert successful email delivery or push receipt. | `habit_reminder_events` |
| Web push subscription | Browser push subscription material persisted for a user (endpoint + `p256dh` + `auth`) so multiple devices can be registered; unsubscribe deletes the row for that endpoint. | `web_push_subscriptions` |

---

## Core entities and relationships

- **User** (`users`)
  - `has_many :sessions`, `has_many :habit_categories`, `has_many :user_habits`, `has_many :weight_logs`, `has_many :menus`, `has_many :recipes`, `has_many :phase_assignments`, `has_many :phase_programs`, `has_many :phase_reminder_events`, `has_many :habit_reminder_events`, `has_many :web_push_subscriptions`; Phase 5 adds `has_many` exercise routines and routine week-range assignments (exact names per schema)
  - Authentication: `has_secure_password`; email normalized (strip, downcase)
  - Profile: `date_of_birth` (submitted via birth-date triplet fields → **`BirthDateTriplet`**), `height_cm` (readonly after set in rules), `timezone` (Rails **`time_zone_select`**; Stimulus **`timezone_autodetect_controller.js`** may set the combobox from **`Intl`** when nothing is preselected), `body_unit_system` (**`metric`** \| **`imperial_us`**, default **`metric`**, **REQ-PROF-003**; Stimulus **`unit_system_toggle_controller.js`** shows only the height inputs for the selected system on registration/profile), `current_weight_kg`, `current_bmi`, `verified`, `allow_menu_freeform` (gates freeform text on menu slots)
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
  - **Habit metrics (REQ-DAY-005):** **habit metric kind** (`none` / `count` / `duration_min`) and **daily target** (when kind ≠ `none`), with template-suggested defaults at provision time where applicable
  - **Per-habit reminders (REQ-HAB-010):** `reminder_enabled` (default false), `reminder_time_of_day` (`HH:MM` in the user’s timezone), `reminder_email`, `reminder_web_push` (defaults false). When enabled: habit must be **active**, time must be present/valid, and **at least one** channel must be selected.
  - `has_many :habit_reminder_events` (idempotent per-day bookkeeping per **REQ-HAB-011**)
  - Partial unique index: among **active** rows, `(user_id, name_normalized)` unique
  - **`activation_date` edits:** may change only while the habit has **zero** completion rows; if any completion exists, changing `activation_date` is forbidden until all completions are removed (including after a user clears every day back to pending).

- **WeightLog** (`weight_logs`)
  - `belongs_to :user`; **`logged_at`** required (instant of weigh-in; ordered by **`logged_at DESC`, `id DESC`** for history); stores **`weight_kg`**, **`height_cm`**, **`bmi`** per entry (immutable **`weight_kg` / `height_cm`** after insert); validations include **`logged_at`** not after “now” in the user’s timezone

- **Menu** (`menus`)
  - `belongs_to :user`, `has_many :menu_entries`, `has_many :phase_assignments`
  - `publicly_shareable` for the authenticated **public menu catalog**; owner toggles on create/edit; **admin** may revoke sharing (moderation). Adopted copies: optional `source_menu_id`, `source_sync_fingerprint`, `adoption_catalog_origin_id` for drift and unavailable-source UX (**REQ-MENU-006**).

- **MenuEntry** (`menu_entries`)
  - `belongs_to :menu`, optional `belongs_to :recipe`
  - Unique `(menu_id, weekday, meal_type)`; `weekday` 0–6 (Sunday..Saturday); `meal_type` one of the canonical habit-aligned keys (`desayuno`, `almuerzo`, `cena`, `merienda`)
  - Content: at least one of `recipe_id` or `freeform_text` when persisted (subject to user preference)

- **Recipe** (`recipes`)
  - `belongs_to :user`, `has_many :menu_entries`; optional `has_one_attached :image`
  - `publicly_shareable`; admin may revoke sharing

- **ExerciseRoutine** (`exercise_routines`)
  - `belongs_to :user`; lines and week-range assignments per **REQ-EXR-001** / **REQ-EXR-002**
  - `publicly_shareable` for the authenticated **public routine catalog**; owner toggles on create/edit; **admin** may revoke sharing (moderation). Adopted copies: optional `source_exercise_routine_id`, `source_sync_fingerprint`, `adoption_catalog_origin_id` for drift and unavailable-source UX (**REQ-EXR-006**).

- **PhaseProgram** (`phase_programs`)
  - `belongs_to :user`; optional self-reference for catalog adoption; `has_many :phase_program_assignments`, **`dependent: :destroy`** (destroying the program removes bundle rows only; **menus and routines** remain user-owned templates unless deleted separately)
  - `publicly_shareable` and adoption metadata under **REQ-PHS-001**

- **PhaseProgramAssignment** (`phase_program_assignments`)
  - `belongs_to :phase_program`, `belongs_to :menu`, `belongs_to :exercise_routine`; `start_week`, `end_week` with DB check constraints (`start_week ≥ 1`, `end_week ≥ start_week`)
  - **Menu** and **ExerciseRoutine** must belong to the **same user** as the program; non-overlapping week ranges **within the same `phase_program_id`** enforced in the model

- **PhaseAssignment** (`phase_assignments`)
  - `belongs_to :user`, `belongs_to :menu`; `start_week`, `end_week` with DB check constraints (`start_week ≥ 1`, `end_week ≥ start_week`)
  - Non-overlapping week ranges per user enforced in the model

- **PhaseReminderEvent** (`phase_reminder_events`)
  - `belongs_to :user`; unique `(user_id, kind, local_date)` for idempotent reminder delivery

---

## Requirement registry

| ID | Requirement | Status |
|----|-------------|--------|
| REQ-PLAT-001 | Application uses Rails 8.x with SQLite, Propshaft, importmap-rails, Turbo, and Stimulus as the default stack. | Implemented |
| REQ-I18N-001 | User-facing copy uses I18n; default locale Spanish (`:es`), English (`:en`) available. | Implemented |
| REQ-AUTH-001 | User can register with email and password; email format and uniqueness enforced; password minimum length enforced. The same sign-up form collects initial **profile** fields (**date of birth**, **timezone**, **body unit system**, **height**) under **REQ-PROF-001** and **REQ-PROF-003**. | Implemented |
| REQ-AUTH-002 | User can sign in with email and password; invalid credentials are rejected without distinguishing which field failed inappropriately. | Implemented |
| REQ-AUTH-003 | Authenticated browser access requires a valid signed session cookie mapping to a `Session` record; otherwise redirect to sign-in. | Implemented |
| REQ-AUTH-004 | User can sign out; session is destroyed. | Implemented |
| REQ-AUTH-005 | Email verification flow uses time-limited signed tokens; invalid links are handled. | Implemented |
| REQ-AUTH-006 | Password reset via email; unverified users cannot reset password until email is verified (per product rules). | Implemented |
| REQ-AUTH-007 | When password changes, sessions other than the current one are invalidated. | Implemented |
| REQ-PROF-001 | Profile and registration enforce presence and validity of `date_of_birth`, `height_cm`, and `timezone` (IANA name set). **`date_of_birth`** is set from **`birth_year` / `birth_month` / `birth_day`** via **`BirthDateTriplet`**: all three present and **`Date.valid_date?`** → persisted date; any blank → **`date_of_birth`** nil (incomplete triplet); invalid calendar day → **`date_of_birth`** error **`invalid_calendar`** (422, no silent coercion). | Implemented |
| REQ-PROF-002 | User stores `current_weight_kg` and `current_bmi`; BMI is derived from weight and height per application rules. | Implemented |
| REQ-PROF-003 | **Body unit preference and conversion:** `users.body_unit_system` is **`metric`** \| **`imperial_us`** (US customary), NOT NULL, default **`metric`**. Canonical storage remains **`weight_kg`** / **`height_cm`**. **`BodyMetrics`** (`app/services/body_metrics.rb`) and **`BodyMetricsHelper`** format and parse display units; registration and profile include a single unit selector; imperial height uses ft + in where applicable. **UX:** Stimulus **`unit_system_toggle_controller.js`** toggles visibility so only the height fields for the **selected** system are shown (metric **cm** vs imperial **ft/in**). **Timezone:** sign-up uses **`time_zone_select`**; **`timezone_autodetect_controller.js`** pre-fills from the browser’s IANA zone via **`Intl.DateTimeFormat().resolvedOptions().timeZone`** when the field has no initial value (user can override). **Copy:** imperial height labeling is I18n-driven (e.g. Spanish **“Imperial pies pulgadas”**). **`ApplicationMailer`** includes **`BodyMetricsHelper`** with a contract spec so templates never interpolate raw canonical columns. Out of scope per product: stone/UK, public API export formats. | Implemented |
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
| REQ-DAY-002 | User marks a habit **done** or **failed** for a calendar day (at least the current day); persistence is per local day and habit. For **habit metrics** (**REQ-DAY-005**), the product may also record **day progress** and derive or sync **`status`** with the **daily target** per REQ-DAY-005. | Implemented |
| REQ-DAY-003 | User may change completion **retroactively** for any **past** local day (no upper bound); **future** days cannot be marked. User may switch between done, failed, and **pending** (pending = no completion row). | Implemented |
| REQ-DAY-004 | **Streak** per habit: longest run of consecutive **due** days where each day is **done**, evaluated only on **closed** days (before “today” in the user’s TZ, the streak does not treat an open today as a failure). A closed due day without **done** breaks the streak (**failed** and absent row are equivalent for streak). Reactivation keeps existing completion history. **Mi Día** computes the displayed streak map via **`Habits::MiDayStreakPrefetch`** (single bounded **`HabitCompletion`** query + **`Habits::Streak`** per due habit), memoized in **`Rails.cache`**; **`Habits::RecordCompletion`** / **`Habits::ClearCompletion`** **`touch`** **`UserHabit`** so cache keys stay coherent (see **`docs/core/DATA_FLOW_MAP.md`** §1.1–1.3, §3). For measurable habits, **“done” for streak** matches the same fulfillment rule as **REQ-DAY-005** (typically reflected in persisted **`status`**). | Implemented |
| REQ-DAY-005 | **Habit metrics:** each **`UserHabit`** has a **habit metric kind** (`none`, `count`, `duration_min`) and a user-editable **daily target** when the kind is not **`none`** (templates may supply suggested defaults at provision time). The single **`HabitCompletion`** row for a local day may store **day progress** (non-negative integer, accumulated that day). **Explicit failed** from the user means the day is **not** fulfilled for streaks and reports even if progress is partial. Otherwise the day counts as **fulfilled** when **day progress** ≥ **daily target**. Persisted **`status`** on **`HabitCompletion`** remains **`done`** or **`failed`** and is **kept in sync** with these rules so **`Habits::Streak`**, **`Habits::MiDayStreakPrefetch`**, and **Informes** share one definition (extends **REQ-DAY-002** and **REQ-DAY-004**). | Implemented |
| REQ-HAB-010 | **Per-habit reminders — configuration:** a `UserHabit` may store an optional reminder configuration with **`reminder_enabled`** default **false**, a **local time-of-day** `HH:MM` (interpreted using the owner’s IANA **`users.timezone`**), and independent channel toggles **`reminder_email`** and **`reminder_web_push`**. If enabled, the habit must be **active**, the time must be present and valid, and **at least one** channel must be selected. | Implemented |
| REQ-HAB-011 | **Per-habit reminders — idempotency:** the sweep creates at most one **`habit_reminder_events`** row per `(user_id, user_habit_id, local_date)`; retries / repeated job runs must not create duplicates (DB uniqueness + `RecordNotUnique` tolerance in the processor). | Implemented |
| REQ-HAB-012 | **Web Push subscriptions (persistence):** authenticated users can **create or update** a subscription row (`endpoint`, `p256dh`, `auth`) and **unsubscribe** by `endpoint`, scoped to **`Current.user`**. Uniqueness is enforced per `(user_id, endpoint)`. **Sending** when a habit reminder fires is **REQ-HAB-013** (this row is persistence + HTTP surface only). | Implemented |
| REQ-HAB-013 | **Per-habit reminder — delivery:** after a **successful** insert into **`habit_reminder_events`** for `(user_id, user_habit_id, local_date)` (and **not** on the idempotent **`ActiveRecord::RecordNotUnique`** path), **`Habits::ProcessHabitReminderForUserHabit`** dispatches **email** when **`reminder_email`** (`HabitReminderMailer#notify` + `deliver_now`, I18n’d) and **Web Push** when **`reminder_web_push`** via **`Habits::DeliverHabitReminderWebPush`** ( **`web-push`** gem, VAPID from Rails credentials / config, I18n JSON payload, best-effort per **`web_push_subscriptions`** row, **destroy** on **`WebPush::InvalidSubscription`** / **`WebPush::ExpiredSubscription`**). Respects the same early-return gates as the processor (inactive habit, reminders off, missing/invalid timezone, habit already **done** for that user-local day per **`Habits::Streak.habit_day_done?`**). | Implemented |
| REQ-WGT-001 | `weight_logs` persist historical weight, height snapshot, BMI, and **`logged_at`** (indexed with `user_id`) for a user. | Implemented |
| REQ-WGT-002 | **Weight log entry:** authenticated user can record weigh-ins over time via a form (**`weight_kg`**, **`logged_at`** in the user’s timezone; no height field on the form); navigation entry points (e.g. home, profile). | Implemented |
| REQ-WGT-003 | **History:** authenticated user can view a paginated list (**30** per page) of their weigh-ins ordered by **`logged_at`** descending, with local date/time, weight, height snapshot, BMI, and delete-with-confirmation that reconciles **`current_*`**. | Implemented |
| REQ-WGT-004 | **Weight log UI units:** weigh-in entry (**`weight_lb`** or **`weight_kg`** by preference), history table, and Informes weight chart (Y-axis, legend, point tooltips) present weight and snapshot height using the viewer’s **`User#body_unit_system`** while persisting only **`weight_kg`** / **`height_cm`**. | Implemented |
| REQ-MENU-001 | Weekly **menu** plan: at most one persisted slot per `(menu, weekday, meal_type)`; slot holds a user-owned **recipe** and/or optional freeform text per profile preference; validations and Hotwire grid editor. | Implemented |
| REQ-MENU-002 | **Recipe** model: name, instructions, optional **ActiveStorage** image; in menu slots, fallback image by meal type when the recipe has no image. | Implemented |
| REQ-MENU-003 | **Phase** anchor `phase_one_starts_on` on user; program **week index** from anchor and user timezone; **phase_assignments** map contiguous week ranges to menus (no overlaps); active menu resolution for current week. | Implemented |
| REQ-MENU-004 | If anchor is more than three **local** days away, flash warning; **reminder** on phase-start day: in-app banner (dismiss for today) and optional email; independent channel prefs; idempotent `phase_reminder_events` and daily sweep job (`config/recurring.yml`). | Implemented |
| REQ-MENU-005 | When current week is **past** all assignment ranges, show extension prompt; **repeat last block** (same menu and span) or link to **add a new range**. | Implemented |
| REQ-MENU-006 | **Public menu catalog:** owner opt-in `publicly_shareable`; authenticated catalog index/show (no author email in HTML); adopt creates one copy per adopter per source with slot copy (recipes duplicated for the adopter) and sync fingerprint; explicit apply-update from source with stale detection; source deleted or made non-public yields unavailable copy UX; **`phase_assignments`** on the copy are unchanged on sync; admin revoke like recipes/routines. See **Acceptance criteria — REQ-MENU-006** below. | Implemented |
| REQ-EXR-001 | **Exercise routine content model:** user-owned weekly routine; ordered lines per weekday (0–6); CRUD + duplicate; delete with cascade of week-range assignments after confirmation. See **Acceptance criteria — REQ-EXR-001** below. | Implemented |
| REQ-EXR-002 | **Program weeks → routine:** same anchor and `Phases::WeekNumber` as menus; `exercise_routine_assignments` with non-overlapping ranges per user; resolve active routine; phase plan UI on `/phase`. See **Acceptance criteria — REQ-EXR-002** below. | Implemented |
| REQ-EXR-003 | **Mi Día + navigation:** active routine context for **`fitness_exercise`** when due; global shortcuts; home and plan entry points. See **Acceptance criteria — REQ-EXR-003** below. | Implemented |
| REQ-EXR-004 | **Phase alerts (routine lane):** shared anchor warning; phase-start reminders coherent with menus; routine lane visible on `/phase`. See **Acceptance criteria — REQ-EXR-004** below. | Implemented |
| REQ-EXR-005 | **Routine plan extension:** when current week is past all routine ranges, extension prompt; repeat last routine block or add new range. See **Acceptance criteria — REQ-EXR-005** below. | Implemented |
| REQ-EXR-006 | **Public exercise routine catalog:** owner opt-in `publicly_shareable`; authenticated catalog index/show (no author email in HTML); adopt creates one copy per adopter per source with line copy and sync fingerprint; explicit apply-update from source with stale detection; source deleted or made non-public yields unavailable copy UX; admin revoke like recipes/menus. See **Acceptance criteria — REQ-EXR-006** below. | Implemented |
| REQ-RPT-001 | **Habit fulfillment report** on **Informes:** per habit, fulfillment with **weekly** (Mon–Sun, user TZ) and **monthly** (civil month, user TZ) breakdown; due-day and completion rules aligned with Mi Día. See **Acceptance criteria — reporting (Phase 7)** below. | Implemented |
| REQ-RPT-002 | **Streak report** on **Informes:** per habit, **current** streak (parity with **`Habits::Streak`**) and **all-time longest** streak; `as_of` date rules match Mi Día. See **Acceptance criteria — reporting (Phase 7)** below. | Implemented |
| REQ-RPT-003 | **Weight progress chart** on **Informes:** visual trend from `weight_logs`; efficient read (indexed `user_id` + `logged_at`), not history pagination; server-rendered SVG; timezone-consistent labels. **Extended (imperial/metric):** Y-axis, legend, and tooltips respect **`User#body_unit_system`** while the series stays **`weight_kg`**-based (acceptance criterion 7 below). See **Acceptance criteria — reporting (Phase 7)** below. | Implemented |
| REQ-CAT-001 | **Public catalog metrics & discovery:** authenticated **`public_menus`**, **`public_exercise_routines`**, **`public_phase_programs`**: template **`public_catalog_adoptions_count`** / **`public_catalog_distinct_adopters_count`** (increment on successful adoption only); **`sort=name`** / **`sort=popular`**; optional **`catalog_listing_facets`**; filters via **`Catalog::ApplyPublicListingFilters`** (`q`, **`difficulty`**, **`tags`**, **`min_weeks`**, **`max_weeks`**); **`PhaseProgram`** facet week span materialized by **`Catalog::MaterializePhaseProgramFacetDuration`** from **`phase_program_assignments`**. Revoke public sharing removes template from index. See **`#### REQ-CAT-001`**. | Implemented |
| REQ-PHS-001 | **Unified phase program (bundle):** user-owned entity grouping menu and exercise routine phase planning for contiguous program weeks; **public catalog** `public_phase_programs` (authenticated index/show, owner **`publicly_shareable`** opt-in); admin **revoke** scopes to currently-public rows (parity with menus/routines). **Adopt:** `Programs::AdoptFromPublicCatalog` + `Programs::ContentFingerprint` duplicate nested menus/routines (via `Menus::CopyMenuForAdopter`, `ExerciseRoutines::CopyRoutineForAdopter`) and segment rows; one copy per adopter per source. **Sync:** `Programs::AdoptionSyncStatus` + `Programs::ApplyAdoptionSourceSync` (fingerprint + expected-origin retry); applying rebuilds segment rows from the current source template via `Programs::PopulateAssignmentsFromSource` (prior duplicated menus/routines may remain orphaned on the account — acceptable MVP). **Apply to user:** `Programs::ApplyBundleToUser` **replaces** all of that user’s existing **`phase_assignments`** and **`exercise_routine_assignments`** with rows copied from the program’s **`phase_program_assignments`** (same week ranges, same menu and routine IDs), in **one transaction** — explicit product choice for MVP (`docs/ROADMAP.md` **#33**). | Implemented |

---

## Requirement registry (planned — roadmap)

Reserved for **future** REQ rows promoted from **Backlog** in `ROADMAP.md`. When a row is implemented, move it to **Requirement registry (implemented)** above.

*(No planned REQ rows in this table right now.)*

### Acceptance criteria — reporting (Phase 7)

These criteria are **testable**; implementation lives under services (e.g. `Reports::`, `Habits::`, `WeightLogs::`) and a **single** Informes surface per **Decisions log — REQ-RPT** below.

#### REQ-RPT-001 — Habit fulfillment

1. **Authenticated user** can view fulfillment stats derived from **`Habits::DueOnDate`** (due days) and **`HabitCompletion`** (`done` / `failed` / absent).
2. **Fulfillment ratio:** For a bounded **local** inclusive date range, **denominator** = count of days in range where the habit is **due**; **numerator** = count of those due days with **`status == "done"`**. **`failed`** and **absent** (no row) both count as not fulfilled.
3. **Weekly breakdown:** The **week** is **Monday through Sunday** in the user’s **current** IANA timezone; stats can be shown for “the week containing” a reference local date (inclusive range).
4. **Monthly breakdown:** The **month** is the **civil calendar month** (1st through last day) in the user’s timezone.
5. **Inactive habits:** A habit with **`active: false`** appears in the report for a period **only if** it has **at least one** completion row **in that period**; if it has **no** activity in the period, **omit** that habit for that period.
6. **Presentation:** UX should make **due vs done** intelligible (e.g. show counts **N/M** or equivalent, not only a bare percentage).
7. **I18n:** User-visible copy uses `es` default, `en` available.

#### REQ-RPT-002 — Streak report

1. **Current streak** for a habit **matches** **`Habits::Streak`** for the same **`user_habit`**, **`as_of`** local date, and the same completion/due rules as **REQ-DAY-004** (including closed “today” behavior and non-due days).
2. **`as_of` parity with Mi Día:** Same rules as Mi Día for selecting the local calendar day (query param, cannot be future, cap at **today** in user TZ).
3. **Longest streak (all-time):** Longest run of **consecutive due days** each marked **done**, using the **same** streak semantics as **REQ-DAY-004** over the habit’s history from activation / lower bound through the evaluated range; **no** persisted aggregate columns are **required** for Phase 7 (optional optimization is backlog).
4. **Inactive habits:** Same intent as **REQ-RPT-001** — omit an **inactive** habit from the **streak** table unless it has **at least one** `HabitCompletion` whose **`completed_on`** falls in the **reference window** shown on Informes for the chosen day: the **inclusive union** of the **Monday–Sunday week** and the **civil month** that contain the user’s selected local reference date (same bounds **`Reports::CalendarPeriodBounds`** uses for fulfillment). Active habits remain listed for streaks regardless of completions in that window.
5. **I18n:** User-visible copy uses `es` default, `en` available.

#### REQ-RPT-003 — Weight progress chart

1. **Data:** Series built from the user’s **`weight_logs`**, ordered for display (typically by **`logged_at`** ascending for left-to-right trend).
2. **Query:** **One** (or minimal) **indexed** read scoped to **`user_id`**, using the existing index pattern from **REQ-WGT-001**; **do not** drive the chart from **`WeightLogs::HistoryPage`** pagination.
3. **Volume:** Default series is **full history** unless a documented cap/downsample is introduced for performance (if so, document in code and cover with a spec).
4. **Timezone:** Axis labels and date interpretation for each point are **consistent** with existing weight history (`logged_at` in user TZ as elsewhere).
5. **Rendering:** **Server-first** or minimal Stimulus (e.g. SVG/polyline); **no** Node bundler unless ADR — see **SYSTEM_ARCHITECTURE.md**.
6. **I18n:** User-visible copy uses `es` default, `en` available.
7. **Body units (extends REQ-PROF-003 / REQ-WGT-004):** The chart’s **Y-axis scale**, **tick labels**, **legend**, and **point tooltips** show weight in the authenticated user’s **`body_unit_system`** ( **`metric`** → kg with the app’s display precision; **`imperial_us`** → lb with **display-only** rounding per **REQ-PROF-003**). The plotted series and backend queries remain driven by canonical **`weight_kg`** (no alternate stored series).

#### Decisions log — REQ-RPT (Phase 7, locked)

| ID | Decision |
|----|----------|
| Q1 | **Week** boundaries: **Monday–Sunday** in user TZ. |
| Q2 | **Month** boundaries: **civil month** in user TZ. |
| Q3 | **Informes navigation:** **Single** route (e.g. **`GET /informes`**) with **tabs or sections** for fulfillment, streaks, and weight — **not** three separate top-level URLs. |
| Q4 | **Fulfillment** denominator uses **due days** only; numerator uses **`done`** only. |
| Q5 | **Longest streak** computed in service layer for Phase 7; **materialized** streak columns are **optional future** optimization (see backlog in **ROADMAP.md**). |

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

#### REQ-EXR-006 — Public catalog, adoption, and sync

1. **Opt-in:** The routine owner can set **`publicly_shareable`** on create/update; default **false**; catalog lists only **`publicly_shareable: true`** routines for authenticated users.
2. **Catalog read:** **Index** and **show** for public routines do not expose private routines; **show** returns **404** when the routine is not public; **author** in HTML is a safe identifier (e.g. numeric id label), **not** email.
3. **Adoption:** An authenticated user other than the owner may **adopt** a public routine **at most once** per source (one copy per `(adopter, source)`); chosen **copy name** follows the same uniqueness rules as other routines; lines are copied; **`source_exercise_routine_id`** and sync metadata are stored.
4. **Sync:** When the source’s **line content** changes, the adopter’s **edit** screen shows a **pending update** state; **apply update** replaces **lines only** (copy **name** and **`exercise_routine_assignment`** links to the same `exercise_routine_id` unchanged). **Stale apply** (source changed again after the form was rendered) is rejected with a clear message.
5. **Unavailable source:** If the source is **deleted** or **no longer public**, the copy shows an **unavailable** message; the copy remains owned by the adopter. **Public show** for a removed routine id does not **500**.
6. **Moderation:** An **admin** (same **`MOONLOOP_ADMIN_EMAILS`** gate as recipes/menus) can **revoke** public sharing on a routine; it disappears from the public catalog.

#### REQ-MENU-006 — Public menu catalog, adoption, and sync (parity REQ-EXR-006)

1. **Opt-in:** The menu owner can set **`publicly_shareable`** on create/update; default **false**; catalog lists only **`publicly_shareable: true`** menus for authenticated users.
2. **Catalog read:** **Index** and **show** for public menus do not expose private menus; **show** returns **404** when the menu is not public; **author** in HTML is a safe identifier (e.g. numeric id label), **not** email.
3. **Adoption:** An authenticated user other than the owner may **adopt** a public menu **at most once** per source (one copy per `(adopter, source)`); chosen **copy name** follows the same uniqueness rules as other menus; **menu entries** are copied; slots that reference the author’s recipes get **new `Recipe` rows owned by the adopter**; **`source_menu_id`** and sync metadata are stored.
4. **Sync:** When the source’s **entry content** changes, the adopter’s **edit** screen shows a **pending update** state; **apply update** replaces **menu entries only** (copy **name** and **`phase_assignments`** to the same `menu_id` unchanged). **Stale apply** (source changed again after the form was rendered) is rejected with a clear message.
5. **Unavailable source:** If the source is **deleted** or **no longer public**, the copy shows an **unavailable** message; the copy remains owned by the adopter. **Public show** for a removed menu id does not **500**.
6. **Moderation:** An **admin** (same **`MOONLOOP_ADMIN_EMAILS`** gate) can **revoke** public sharing on a menu; it disappears from the public catalog.

#### REQ-CAT-001 — Public catalog metrics, popularity sort, and discovery

**Scope:** Extends **REQ-MENU-006**, **REQ-EXR-006**, and **REQ-PHS-001** public catalog **read** and **adoption** flows (`docs/ROADMAP.md` **#34**). No anonymous catalog; no view-hit analytics.

1. **Metrics on templates:** Each **`Menu`**, **`ExerciseRoutine`**, and **`PhaseProgram`** that can be listed as a catalog **source** carries **`public_catalog_adoptions_count`** and **`public_catalog_distinct_adopters_count`**, both integers **≥ 0**, **NOT NULL**, default **0** (see **`docs/core/SCHEMA_REFERENCE.md`**).
2. **When counters move:** On **successful** completion of **`Menus::AdoptFromPublicCatalog`**, **`ExerciseRoutines::AdoptFromPublicCatalog`**, or **`Programs::AdoptFromPublicCatalog`**, inside the same **database transaction**, increment **`public_catalog_adoptions_count`** on the **source template** by **1**. Increment **`public_catalog_distinct_adopters_count`** by **1** only when the adoption establishes the adopter’s **first** copy from that source (the service already rejects **`:already_adopted`** — a second attempt must **not** double-count).
3. **Concurrency:** Counter updates must be **race-safe** for concurrent adopters (row lock or atomic increment on the template row — implementation detail; integration or unit coverage as agreed in tests).
4. **Catalog sort:** Each public index accepts a **sanitized** sort parameter; **`sort=name`** and **`sort=popular`** are supported (**popular** uses the adoption counters; tie-breaker **deterministic**, e.g. `id` or `name`). Default sort is **explicit** in code and **locked by request specs**.
5. **Catalog UI:** Public index markup shows **both** metrics per item with **I18n** (`es` / `en`) and is **accessible** (not color-only).
6. **`catalog_listing_facets`:** Optional **one** row per listable (`Menu` / `ExerciseRoutine` / `PhaseProgram`); **unique** `(listable_type, listable_id)`; fields support discovery (e.g. goal phrase, closed difficulty, normalized tags, optional week-range bounds for duration filters). Only the **listable owner** may create or update the facet; public reads join only **public** templates.
7. **Filters:** On **`public_menus`**, **`public_exercise_routines`**, and **`public_phase_programs`** index actions, optional query params (all ignored when absent, empty, or invalid; **no 400**): **`q`** — case-insensitive substring match on facet **`goal_phrase`** (max length 255); **`difficulty`** — exact match on **`Catalog::ListingFacet::DIFFICULTY_LEVELS`**; **`tags`** — comma- or array-valued list of tag slugs; **AND** semantics (every listed slug must appear in **`normalized_tags`**); **`min_weeks`** / **`max_weeks`** — positive integers constraining the facet duration span using **`COALESCE(duration_weeks_max, duration_weeks_min)`** and **`COALESCE(duration_weeks_min, duration_weeks_max)`** so a template matches when its span overlaps the requested bounds (each bound applies only when parseable). Any filter requires an **inner join** to **`catalog_listing_facets`**, so listables **without** a facet row are **excluded** when at least one filter is active. Combined filters use **AND**. Implementation: **`Catalog::ApplyPublicListingFilters`**.
8. **Phase programs — duration:** For **`PhaseProgram`** listables, **`catalog_listing_facets.duration_weeks_min`** / **`duration_weeks_max`** are **materialized** from **`phase_program_assignments`**: **minimum** `start_week` and **maximum** `end_week` across segments (no segments → both **NULL**). **`Catalog::MaterializePhaseProgramFacetDuration`** runs after **`PhaseProgram`** save and after **`PhaseProgramAssignment`** commit. The program edit UI does **not** collect manual week bounds for the facet (menus/routines still do). **`Catalog::ApplyPublicListingFilters`** unchanged (reads facet columns).
9. **Revoke:** Admin or owner making a template **non-public** removes it from catalog listings; persisted counters and facet rows may remain but **must not** affect public queries.

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
| Q8 | **Public sharing** of routines (catalog, adoption, sync, moderation): **REQ-EXR-006**; parity intent with **Done #29** / recipe catalog (see **ROADMAP** **#30**). |
| Q9 | **Reuse** existing phase-assignment UX for routine ranges. |
| Q10 | Mi Día: day preview **plus** link to **full week** view for the active routine. |
| Q11 | **Parity with menus:** **REQ-MENU-004**-style alerts/reminders and **REQ-MENU-005**-style plan-ended extension apply to the **routine** lane — see **REQ-EXR-004** and **REQ-EXR-005**. |
| Q12 | **Delete routine** when week-range assignments exist: **allowed**; user sees a **prior warning** that assignments will be **removed automatically**; on confirm, system **deletes those ranges then the routine** (transactional). |
| Q13 | Routine **name uniqueness** per user: **same rules as `Menu`**. |
| Q14 | User can **duplicate** a routine (copy) into a new owned routine. |
| Q15 | Entry points from **home** / primary navigation, not only Mi Día. |

---

## Key workflows (summary)

1. **Registration and verification** — User signs up with email/password plus profile triplet DOB, **`time_zone_select`** (optional autodetect), unit system, and height fields → optional verification email → can complete password reset only when rules allow → sessions created on sign-in.
2. **Profile** — User maintains DOB (same triplet + **`BirthDateTriplet`** rules as registration), height, timezone, weight; BMI updated from weight and height.
3. **Habit provisioning** — On sign-in, job ensures template-backed default categories and habits exist once per logical template `code`.
4. **Category lifecycle** — CRUD categories; destroy prevented if habits still reference the category.
5. **Habit lifecycle** — Create personal habit or from template; toggle active; name collision only among active habits; frequency params validated by type.
6. **Next occurrence (preview)** — For scheduling previews/tests, `Habits::NextOccurrence` implements the same frequency types as Mi Día scheduling (`daily`, `weekdays`, `every_x_days`, `monthly`), aligned with `Habits::DueOnDate` where applicable. Monthly respects shorter months (end-of-month clamp).
7. **Informes** — Authenticated user opens **`GET /informes`**, picks a reference local day (same rules as Mi Día), and views habit fulfillment (week + month), current and longest streaks per habit, and a weight trend chart from `weight_logs`.
8. **Public menu catalog** (**REQ-MENU-006**) — Owner opts in with **`publicly_shareable`** on create/update; authenticated users browse **`public_menus`** and may **adopt** (one copy per source per adopter; recipes duplicated for the adopter); **apply update** syncs slot content only; admin **revoke** removes the menu from the catalog.

---

## Implementation deep dive

Feature-specific docs can be linked here as they are written, for example:

- Registration / profile: `RegistrationsController`, `ProfilesController`, concern **`BirthDateTriplet`**; views **`registrations/new`**, **`profiles/edit`**, partial **`shared/_birth_date_fields`**; Stimulus **`birth_date_controller.js`**, **`unit_system_toggle_controller.js`**, **`timezone_autodetect_controller.js`** (**REQ-AUTH-001**, **REQ-PROF-001**, **REQ-PROF-003**)
- Habits core: models under `app/models/user_habit.rb`, `habit_category.rb`, `global_habit_template.rb`; services under `app/services/habits/`
- Provisioning: `ProvisionDefaultHabitsJob` and sign-in integration
- Phase 4 (Alimentación): `Menu`, `MenuEntry`, `Recipe`, `PhaseAssignment`, `PhaseReminderEvent`; services under `app/services/menus/` and `app/services/phases/`; Turbo menu grid under `Menus::MenuEntriesController`; **`PublicMenusController`**, adoption/sync services (`Menus::AdoptFromPublicCatalog`, `ApplyAdoptionSourceSync`, …); Solid Queue job `Phases::SweepPhaseStartRemindersJob` (see `config/recurring.yml`); admin moderation under `Admin::*` gated by `MOONLOOP_ADMIN_EMAILS` (**REQ-MENU-006**)
- Phase 5 (Rutinas de ejercicio): models `ExerciseRoutine`, `ExerciseRoutineLine`, `ExerciseRoutineAssignment`; services under `app/services/exercise_routines/`; `ExerciseRoutinesController`, `ExerciseRoutineAssignmentsController`, `PublicExerciseRoutinesController`, `Admin::ExerciseRoutinesController`; Mi Día (`MyDayController`) + `/phase` integration; parity **REQ-EXR-004** / **REQ-EXR-005** with **REQ-MENU-004** / **REQ-MENU-005**; public catalog **REQ-EXR-006**. See **Acceptance criteria — exercise routines (Phase 5)**, **REQ-EXR-006**, and **Decisions log — REQ-EXR** in this file.
- Phase 7 (Informes): `GET /informes` → `ReportsController#show`; services **`Reports::CalendarPeriodBounds`**, **`Habits::FulfillmentForPeriod`**, **`Habits::LongestStreak`**, **`Habits::ReportCurrentStreak`**, **`WeightLogs::ChartSeries`**; **`Habits::DueOnDate`** supports optional **`schedule_only:`** for inactive-habit reporting. See **REQ-RPT-001**–**003** and **Decisions log — REQ-RPT** in this file.

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
