# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Changed

- **Registration & profile (roadmap #40–#42):** triplet DOB fields with server-side **`BirthDateTriplet`** (`app/services/birth_date_triplet.rb`), shared **`shared/_birth_date_fields`**, Stimulus **`birth_date`**, **`unit-system-toggle`** (CSS `hidden` + radio targets), and **`timezone-autodetect`**; timezone **`select`** uses i18n prompt **`shared.timezone_select_prompt`**; form error summaries restore **`forms.errors.header`** / **`recipes.form.errors_header`** where applicable. Flash for success remains in **`layouts/application`**.

### Fixed

- Public catalog adoption: `ActiveRecord::RecordInvalid` on menu and exercise routine adopt flows now surfaces **i18n** flash keys instead of raw `full_messages` (`adoption.invalid_record.*`).
- Habit metrics: added **`marked_failed_by_user`** on `habit_completions` so Mi Día can show **“In progress”** for partial measurable days while keeping **`status`** aligned with streaks/reports; public catalog author line uses a **stable non-PII code** derived from the user id (not the raw numeric id in copy).

### Changed

- Mi Día / rachas: `Habits::MiDayStreakPrefetch` loads streak window completions in one query, caches the `user_habit_id => streak_count` map in `Rails.cache`, and relies on `UserHabit#touch` after `Habits::RecordCompletion` / `Habits::ClearCompletion` so cache keys stay coherent (REQ-DAY-004; roadmap #28).
- Habits: removed `weekly` as a `frequency_type`; “once per week” is stored as `weekdays` with a one-element array. Data migration copies legacy rows using a **nested frozen resolver** (no dependency on `app/` autoload). `Habits::LegacyWeeklyWeekdayResolver` mirrors that logic for tests and tooling (REQ-HAB-005). `Habits::NextOccurrence` covers `daily`, `weekdays`, `every_x_days`, and `monthly`, aligned with `Habits::DueOnDate` for schedule types used in Mi Día.

### Added

- Web UI scaffolding: semantic app navigation + skip link, accessibility CSS, improved “Mi Día” view, and semantic public catalog list markup. Added/updated system and request specs to lock behavior (including Turbo-friendly 422 handling) and synced locale keys (`config/locales/es.yml`, `config/locales/en.yml`).
- **Programas de fase (bundles)** roadmap **#33**: `PhaseProgram` + `PhaseProgramAssignment`, aplicar plantilla al plan de menú y rutina en una transacción (`Programs::ApplyBundleToUser`), catálogo público, adopción y sync de origen (`Programs::AdoptFromPublicCatalog`, `Programs::ApplyAdoptionSourceSync`), copy helpers para menús/rutinas del adoptante, UI e i18n, REQ-PHS-001 en `docs/core/SPEC.md`, integración documentada en `docs/core/DATA_FLOW_MAP.md`, spec de integración en `/phase` tras aplicar un programa.
- **Per-habit reminders — delivery (REQ-HAB-013):** after a successful `habit_reminder_events` insert, `Habits::ProcessHabitReminderForUserHabit` sends `HabitReminderMailer#notify` (`deliver_now`) when `reminder_email` and runs `Habits::DeliverHabitReminderWebPush` when `reminder_web_push` (`web-push` gem, VAPID via `config/initializers/habit_web_push.rb`, I18n payload; per subscription: remove stale rows on `WebPush::InvalidSubscription` / `ExpiredSubscription`, log and continue on other send errors). Idempotency: DB uniqueness + `RecordNotUnique` (no model-level uniqueness validation on `HabitReminderEvent`). Docs: `SPEC.md`, `DATA_FLOW_MAP.md` §1.8, `ADRs/0001`, `SCHEMA_REFERENCE.md`, `ROADMAP.md` Done **#35**; ADR documents MVP tradeoff if delivery fails after insert.
- **Per-habit reminders — foundation (REQ-HAB-010–012):** preferences on `UserHabit`, Solid Queue sweep + processor with idempotent `habit_reminder_events`, Web Push subscription persistence + subscribe/unsubscribe endpoints, `HabitReminderMailer` + templates (channel wiring is REQ-HAB-013, above).
- Phase 7 — **Informes** (`GET /informes`): habit fulfillment (week Mon–Sun and civil month, `Habits::FulfillmentForPeriod` + `DueOnDate` with optional `schedule_only` for inactive habits with activity in range), current and longest streaks (`Habits::ReportCurrentStreak`, `Habits::LongestStreak`), weight trend via server-rendered SVG (`WeightLogs::ChartSeries`), orchestration in `Reports::ShowPage`, i18n (`es` / `en`), home link, and REQ coverage for `REQ-RPT-001`–`REQ-RPT-003` (see `docs/core/SPEC.md`).
- Phase 6 — **Weight log**: `logged_at` on `weight_logs`, register weigh-ins (`weight_kg` + local datetime), paginated history (30 per page) with delete + confirmation, reconciliation of profile `current_weight_kg` / `current_bmi` from the latest `logged_at`, and REQ coverage for `REQ-WGT-001`–`REQ-WGT-003` (see `docs/core/SPEC.md`).
- Phase 5 — **Exercise routines**: weekly routine lines per weekday, week-range assignments on `/phase` (same anchor as menus), Mi Día integration for `fitness_exercise`, dual “plan ended” / repeat-last for menu vs routine lanes, CRUD + duplicate + transactional delete with assignment cascade, home and plan entry points, and REQ coverage for `REQ-EXR-001`–`REQ-EXR-005` (see `docs/core/SPEC.md`).
- Phase 4 — **Alimentación**: weekly **menus** (sparse grid + Turbo slot updates), **recipes** with Active Storage images and public sharing, **phase plan** (anchor date, week assignments, active menu resolution), **phase start reminders** (Solid Queue sweep + in-app banner with dismiss-for-today), **plan-ended** extension UX (repeat last assignment or new range), admin moderation to revoke public sharing on menus/recipes, Mi Día shortcut to the phase area, and REQ coverage for `REQ-MENU-001`–`REQ-MENU-005` (see `docs/core/SPEC.md`).
- Phase 3 — **Mi Día**: `habit_completions` persistence, `Habits::DueOnDate` / streak / completion services, “Mi Día” screen with date navigation, mark done/failed/clear, and roadmap REQ-DAY-001–004 (see `docs/core/SPEC.md`).
- Phase 2 — Habits core: global templates, per-user categories and habits, default provisioning job on sign-in, frequency fields and validations, habits UI (grouped listing, personal habit, add from template, activate/deactivate).
- Internationalization: Spanish default locale, English secondary; shared Active Record error messages and habit/user copy.
- Requirements registry and REQ-ID comments in RSpec; Cursor rules for SPEC/spec traceability.
- `docs/core/SPEC.md` and `docs/core/SYSTEM_ARCHITECTURE.md` aligned with the Moonloop stack (authentication-zero, Propshaft, Hotwire, SQLite).

### Fixed

- Sign-up form uses `model: @user` and `params.require(:user)` so labels match i18n and system specs can find fields.
