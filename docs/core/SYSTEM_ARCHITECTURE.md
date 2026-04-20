# System Architecture & Boundaries

**Purpose:** Technical boundaries for Moonloop. Changes that contradict this document need an explicit ADR or product decision, not silent drift.

## 1. Technology stack

| Layer | Choice |
|--------|--------|
| **Language / runtime** | Ruby 3.3.x (see `.ruby-version`) |
| **Framework** | Ruby on Rails ~> 8.1 |
| **App server** | Puma |
| **Database** | SQLite3 (development, test, and default production posture in this repo) |
| **Assets** | Propshaft; JavaScript via `importmap-rails` (no default Node/npm asset pipeline) |
| **Frontend** | Hotwire: `turbo-rails`, `stimulus-rails`; server-rendered ERB |
| **Auth** | `authentication-zero` + `has_secure_password` (session records, signed cookie); not Devise |
| **Background / infra gems** | `solid_cache`, `solid_queue`, `solid_cable` (Rails 8 Solid stack) |
| **Deploy (optional)** | Kamal, Thruster (see Gemfile) |
| **Tests** | RSpec, FactoryBot, Capybara, Selenium (system specs) |

## 2. Architectural paradigm

- **Server-rendered first:** Controllers render HTML; Turbo handles navigation and forms unless explicitly disabled.
- **Thin controllers:** Non-trivial workflows go to **service objects** under `app/services/` (e.g. `Habits::*`, `Auth::*`, `Menus::*`, `Phases::*`, **`ExerciseRoutines::*`**, **`Programs::*`** (phase program bundles: **`ApplyBundleToUser`**, **`AdoptFromPublicCatalog`**, **`ApplyAdoptionSourceSync`**, **`AdoptionSyncStatus`**, **`PopulateAssignmentsFromSource`**, **`ContentFingerprint`**, **REQ-PHS-001**), **`Catalog::*`** (public catalog filters **`ApplyPublicListingFilters`**, phase-program facet duration **`MaterializePhaseProgramFacetDuration`**, **REQ-CAT-001**), **`Reports::*`**). Mi Día and daily tracking use e.g. **`Habits::DueOnDate`** (due-day rules), **`Habits::DueHabitsForDay`** (list for a local day), **`Habits::RecordCompletion`** / **`Habits::ClearCompletion`** (persist or remove a completion row), **`Habits::Streak`** (streak from completions + schedule), and **`Habits::NextOccurrence`** (next calendar day for previews; aligned with due-day logic where applicable). Menu slots delegate persistence to **`Menus::UpsertEntry`**; phase week math and reminders use **`Phases::*`** services and **`Phases::SweepPhaseStartRemindersJob`**; **per-habit reminders** use **`Habits::SweepHabitRemindersJob`** + **`Habits::ProcessHabitReminderForUserHabit`** (Solid Queue schedule in **`config/recurring.yml`**; idempotent **`habit_reminder_events`** per **REQ-HAB-011**). **Web push (browser Push API)** is treated as **standards-based Web Push** (not FCM inside the Rails app); today the app persists **`web_push_subscriptions`** and exposes subscribe/unsubscribe endpoints — **delivery/orchestration** is explicitly deferred (see **`docs/core/ADRs/0001-habit-reminders-web-push.md`**). **exercise routines** (weekly lines, phase week assignments, Mi Día context, plan-ended / repeat-last parity with menus) use **`ExerciseRoutines::*`** (see `REQ-EXR-*` in `SPEC.md`). **Weight log** orchestration uses **`WeightLogs::HistoryPage`** (paginated history listing), **`WeightLogs::ChartSeries`** (full ascending series for Informes chart), **`WeightLogs::LoggedAtParamParser`** (raw `datetime-local` → `Time` in the user’s zone), **`WeightLogs::ReconcileUserCurrentStats`** (sync **`User#current_weight_kg`** / **`current_bmi`** from latest **`logged_at`**), and **`WeightLogs::DestroyLog`** (delete + reconcile); persistence of a new snapshot still goes through **`LogWeightService`** (see `REQ-WGT-*` in `SPEC.md`). **Reporting (Phase 7)** uses **`Reports::CalendarPeriodBounds`**, **`Habits::FulfillmentForPeriod`**, **`Habits::LongestStreak`**, **`Habits::ReportCurrentStreak`**, and **`ReportsController#show`** at **`/informes`** (see **`REQ-RPT-*`** in `SPEC.md`).
- **Mi Día streak read cache:** The **`user_habit_id → streak_count`** map for the Mi Día screen may be memoized in **`Rails.cache`** via **`Habits::MiDayStreakPrefetch`** (bounded completion query + **`Habits::Streak`** per due habit). **`Habits::RecordCompletion`** and **`Habits::ClearCompletion`** **`touch`** the parent **`UserHabit`** on success so cache keys stay coherent. See **`docs/core/DATA_FLOW_MAP.md`** (§1.1–1.3, §3) and **`docs/core/SPEC.md`** (**REQ-DAY-004**).
- **Service call style:** Prefer **keyword arguments** on `.call` APIs; when assembling kwargs from a Hash, splat with `**` so Ruby does not treat a single Hash as a positional argument.
- **Forms (accessibility):** For server-rendered validation, error summaries should use a stable `id` and `role="alert"`; fields with errors should expose `aria-invalid` and `aria-describedby` pointing at that summary (see **`ApplicationHelper#aria_for_field`**).
- **Admin moderation:** Revoking public sharing uses `Admin::BaseController` + `MOONLOOP_ADMIN_EMAILS` (comma/space-separated list, case-insensitive). Revoke actions scope targets to **currently publicly shareable** rows so moderation cannot toggle arbitrary IDs off-catalog.
- **Domain rules in models** where they are simple validations and associations; extract when complexity or cross-cutting orchestration grows.
- **Internationalization:** Default locale `es`; `en` available. User-visible strings go through `I18n` / `t(...)`.
- **Traceability:** Requirements live in `docs/core/SPEC.md` (`REQ-*` IDs). Specs use `# [REQ-…]` comments per `.cursor/rules/spec-req-traceability.mdc`.
- **Immutable migration logic:** One-off **data** migrations that rewrite legacy column values (for example normalizing `user_habits.frequency_type`) must **not** call arbitrary `app/services` classes from `db/migrate`, so fresh `db:migrate` runs do not depend on Zeitwerk autoload or on later refactors of application code. Keep a **frozen resolver** colocated with the migration (nested class on the migration, e.g. `MigrateWeeklyUserHabitsToWeekdays::WdayResolver`). When the same rules are needed for **automated tests or tooling**, mirror them in a small, spec-covered service under `app/services/` (e.g. `Habits::LegacyWeeklyWeekdayResolver`) and state in comments on **both** sides that behavior must stay aligned.
- **Markup in ERB:** Views may use utility-style class names (for example Tailwind-like `text-2xl`, `border-gray-300`) with styles supplied under `app/assets/stylesheets`. The Gemfile does not include `tailwindcss-rails` unless that pipeline is adopted explicitly.

## 3. Forbidden or discouraged (without ADR)

- **jQuery** or **CoffeeScript** for new frontend code.
- **Devise** (or parallel auth frameworks) while the app is standardized on authentication-zero.
- **Hardcoded user-facing strings** in views, controllers, flash, or mailers (use I18n keys).
- **Introducing a Node-based bundler** (Webpack/Vite) for the default asset path unless an ADR accepts the operational cost.
- **Fat controllers** that encode business rules that belong in services or the domain layer.

## 4. Environment and infrastructure

- **Configuration:** Rails credentials and environment-specific config under `config/`.
- **Jobs:** Active Job with Solid Queue where enabled; tests use the test adapter unless configured otherwise.
- **Browser support:** `ApplicationController` restricts to modern browsers per `allow_browser versions: :modern`.

## 5. Related documents

- `docs/core/SPEC.md` — requirements registry and glossary.
- `docs/core/DATA_FLOW_MAP.md` — entity flows and side-effects (e.g. Mi Día, habit completions, menus, phase plan).
- `docs/core/SCHEMA_REFERENCE.md` — tables/columns mapped to SPEC (regenerated/updated when schema changes).
- `docs/ROADMAP.md` — phased delivery.
- `docs/ai/code_review_prompt.md` — self-review checklist aligned to this stack.
