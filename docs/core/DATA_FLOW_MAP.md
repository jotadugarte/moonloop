# Data Flow & Side-Effect Map

**Purpose:** Maps how entities mutate and propagate throughout the system. AI agents must consult this document to ensure they do not orphan data or bypass necessary side-effects.

## 1. Primary data flows

### 1.1 Mi Día (read)

1. **Browser** requests `GET /mi_dia` with optional `fecha` (ISO date, user-local calendar day).
2. **`MyDayController#show`** resolves “today” and the selected day in the user’s **current** IANA timezone; rejects future dates and invalid `fecha`.
3. **`Habits::DueHabitsForDay`** loads active `UserHabit` rows for the user and filters to habits **due** on that civil date via **`Habits::DueOnDate`** (inactive habits never appear).
4. **`HabitCompletion`** rows for `(user_habit_id ∈ due habits, completed_on = selected day)` build the per-habit done/failed/pending UI state (pending = no row). For measurable habits, **`status`** may be `failed` while the day is only **below target** (not yet fulfilled); **`marked_failed_by_user`** distinguishes that case from an **explicit** user failure so the view can show an **in progress** label without changing streak/report semantics (still driven by **`status`** per **REQ-DAY-005**).
5. **`Habits::MiDayStreakPrefetch`** loads completion rows for the streak walk window (`user_habit_id ∈ due habits`, `completed_on` from the **min** per-habit lower bound through the selected day, narrow `SELECT`) and runs **`Habits::Streak`** per due habit with that preloaded map (**REQ-DAY-004**). The resulting map is stored in **`Rails.cache`** (key: user id, selected local date, and fresh `user_habits.id` + `updated_at` tuples). **`Habits::RecordCompletion`** / **`Habits::ClearCompletion`** **`touch`** the **`UserHabit`** so the cache key advances after writes.
6. **Exercise context (REQ-EXR-003):** **`Phases::WeekNumber.for_local_date`** yields the program week index (or nil if no anchor / before anchor). **`ExerciseRoutines::ResolveActiveRoutine`** returns the routine mapped to that week via **`exercise_routine_assignments`**, independent of menu assignments.
7. **Ejercicio habit:** the `UserHabit` joined to **`global_habit_templates.code == "fitness_exercise"`** is loaded separately when needed (e.g. inactive habit not in the due list). Inline routine preview on Mi Día appears only when that habit is **due** and **active**; a global shortcut to **`/exercise_routines`** and **`/phase`** is always shown.

### 1.2 Mark done / failed (write)

1. **Browser** submits `POST /habit_completions` with `user_habit_id`, `completed_on`, `status` (`done` or `failed`), and optional **`day_progress`** for measurable habits.
2. **`HabitCompletionsController`** scopes the habit to **`Current.user`**, parses the local date, and calls **`Habits::RecordCompletion`**.
3. **`Habits::RecordCompletion`** enforces: owner, habit active, date not in the future, date is a **due** day per `DueOnDate`, status allowed; then **`find_or_initialize_by`** `(user_habit, completed_on)` and saves **`HabitCompletion`** (unique per day per habit), persisting **`day_progress`**, synced **`status`**, and **`marked_failed_by_user`** per **REQ-DAY-005**. On success it **`touch`**es **`UserHabit`** so **`Habits::MiDayStreakPrefetch`** cache keys (driven by `updated_at`) stay coherent.
4. **Redirect** back to Mi Día (with `fecha` preserved for past days).

### 1.3 Clear → pending (delete)

1. **Browser** submits `DELETE /habit_completions/:id`.
2. Controller loads the row through a join scoped to **`Current.user`**.
3. **`Habits::ClearCompletion`** verifies owner and active habit, then **`destroy!`** the row (pending = no row) and **`touch`**es the parent **`UserHabit`** for the same cache-key coherence as writes.

### 1.4 Menu grid slot (read + write via Turbo)

1. **Browser** loads `GET /menus/:id/edit`; controller builds a sparse map of `menu_entries` keyed by `(weekday, meal_type)` and renders the grid partials.
2. **Create/update slot:** `POST /menus/:menu_id/menu_entries` with Turbo; **`Menus::UpsertEntry`** validates ownership, meal type, weekday, user freeform preference, and **dish** ownership (referenced **`Dish`** must belong to the menu owner); creates/updates/destroys **`MenuEntry`** as needed.
3. **Response:** `turbo_stream.replace` for the slot frame only (partial `menus/slot`).
4. **Clear slot:** `DELETE .../menu_entries/clear` removes the row if present; same Turbo replace with empty slot.

### 1.5 Phase plan (anchor, assignments, active menu + routine)

1. **Browser** loads `GET /phase`; **`PhasesController`** sets `week_index` via **`Phases::WeekNumber.today_for`**, resolves **`Phases::ResolveActiveMenu`** and **`ExerciseRoutines::ResolveActiveRoutine`**, loads ordered **`phase_assignments`** and **`exercise_routine_assignments`**, and computes in-app reminder visibility and **two** “plan ended” flags via **`Phases::PhaseStartInAppReminderVisible`**, **`Phases::PlanEnded`** (menu lane), and **`ExerciseRoutines::PlanEnded`** (routine lane).
2. **Patch anchor / reminder prefs:** `PATCH /phase` updates **`User`** (`phase_one_starts_on`, reminder booleans); may set flash **notice** and **alert** when anchor is more than three local days ahead.
3. **Menu assignments CRUD:** **`PhaseAssignmentsController`**, scoped to **`Current.user`**; overlaps rejected at validation.
4. **Routine assignments CRUD:** **`ExerciseRoutineAssignmentsController`**, scoped to **`Current.user`**; overlaps rejected among **routine** assignments only.
5. **Plan extension (menus):** **`Phases::RepeatLastPhaseAssignment`** duplicates the last contiguous menu assignment block forward when the user confirms.
6. **Plan extension (routines):** **`ExerciseRoutines::RepeatLastAssignment`** duplicates the last contiguous **routine** assignment block forward when the user confirms.
7. **Phase program bundles (`REQ-PHS-001`):** **`PhaseProgramsController`** / **`PhaseProgramAssignmentsController`** manage a user-owned **`PhaseProgram`** and its **`phase_program_assignments`** (one menu + one exercise routine per contiguous week range; non-overlapping ranges **within** the program). **`Programs::ApplyBundleToUser`** **replaces** the user’s global **`phase_assignments`** and **`exercise_routine_assignments`** in one transaction from those segments. **`GET /phase`** still resolves the active menu and routine only via **`Phases::WeekNumber`** + **`Phases::ResolveActiveMenu`** + **`ExerciseRoutines::ResolveActiveRoutine`** on the **same** assignment tables — there is no parallel week-index path. Public catalog, adopt, and source sync use **`PublicPhaseProgramsController`**, **`Programs::AdoptFromPublicCatalog`**, **`Programs::AdoptionSyncStatus`**, **`Programs::ApplyAdoptionSourceSync`**, and **`Programs::PopulateAssignmentsFromSource`** (see SPEC).

### 1.6 Exercise routines (CRUD, duplicate, destroy)

1. **Browser** uses **`ExerciseRoutinesController`** for list/create/edit/update; **`POST …/duplicate`** copies structure to a new routine.
2. **Destroy with assignments:** **`GET …/confirm_destroy`** warns that week-range rows will be removed; confirming invokes **`ExerciseRoutines::DestroyRoutine`**, which deletes all **`exercise_routine_assignments`** for that routine then the **`exercise_routine`** in one transaction.

### 1.7 Phase-start reminders (async)

1. **Solid Queue** runs **`Phases::SweepPhaseStartRemindersJob`** on the schedule in **`config/recurring.yml`**.
2. For each user whose **local today** is a phase-start day and prefs allow, **`Phases::ProcessPhaseStartReminderForUser`** creates idempotent **`PhaseReminderEvent`** rows and sends mail when email is enabled.
3. **In-app banner:** rendered on **`PhasesController#show`** when an event applies and the user has not dismissed for that local day (`phase_reminder_dismissed_on`); **`POST /phase/dismiss_reminder`** sets dismissal to local today.

### 1.8 Per-habit reminders (async, MVP)

1. **Solid Queue** runs **`Habits::SweepHabitRemindersJob`** on the schedule in **`config/recurring.yml`** (currently **every minute** in `development` / `production` — tune per ops constraints).
2. The sweep selects **active** `UserHabit` rows with **`reminder_enabled`** and a non-blank **`reminder_time_of_day`**, then filters to habits whose owner has a valid IANA timezone and whose **current local `HH:MM`** matches the configured time.
3. For each match, **`Habits::ProcessHabitReminderForUserHabit`** computes the habit owner’s **local date** from **`Time.current`** in that timezone, returns early when the habit is inactive/disabled, timezone is missing/invalid, or the habit is already considered **done for that local day** via **`Habits::Streak.habit_day_done?`** (same “done” notion as Mi Día / streaks for measurable habits).
4. **Idempotency:** on success it inserts **`habit_reminder_events`** for `(user_id, user_habit_id, local_date)`; **`ActiveRecord::RecordNotUnique`** is treated as success so retries do not duplicate logical processing (**REQ-HAB-011**). Uniqueness is enforced at the **database** so the processor observes **`RecordNotUnique`** (not a model validation short-circuit).
5. **Channels (delivery — REQ-HAB-013):** after a **successful** event insert, **`Habits::ProcessHabitReminderForUserHabit`** sends **email** when **`reminder_email`** (`HabitReminderMailer#notify`, `deliver_now`) and invokes **`Habits::DeliverHabitReminderWebPush`** when **`reminder_web_push`**. Neither runs when the insert hits **`RecordNotUnique`** (same user-local day already processed).
6. **Web Push:** authenticated clients **`POST /web_push_subscription`** / **`DELETE /web_push_subscription`** persist **`web_push_subscriptions`** (**REQ-HAB-012**). **`Habits::DeliverHabitReminderWebPush`** encrypts an I18n payload with the **`web-push`** gem using VAPID material from **`config/initializers/habit_web_push.rb`** (credentials / ENV); invalid/expired endpoints (**`WebPush::InvalidSubscription`** / **`WebPush::ExpiredSubscription`**) **delete** the stale row; other per-subscription send errors are **logged** and processing **continues** for the remaining subscriptions (best-effort batch).

### 1.9 Weight log (create, list, delete, reconcile)

1. **Entry form (`REQ-WGT-002`):** **`GET /weight_logs/new`** → **`POST /weight_logs`** with **`weight_kg`** and **`logged_at`** (datetime-local string). **`WeightLogs::LoggedAtParamParser`** turns the raw field into a **`Time`** in the user’s **IANA timezone** (blank input → **`Time.current`**; invalid parse → validation error on **`logged_at`**). Height is **not** edited on this form; each persisted row snapshots **`User#height_cm`** at save time. **`LogWeightService`** creates **`WeightLog`** (BMI computed on the model) inside a transaction, then **`WeightLogs::ReconcileUserCurrentStats`**, which sets **`users.current_weight_kg`** and **`users.current_bmi`** from the **`WeightLog`** row with **maximum `logged_at`** (tie-break **`id` DESC**), or **`nil`** if no logs remain. A **retroactive** `logged_at` must not overwrite “current” if a newer weigh-in already exists. **Display and form input units** follow **`User#body_unit_system`** (**REQ-PROF-003**, **REQ-WGT-004**): persistence remains **`weight_kg`** / **`height_cm`** only; **`BodyMetrics`** handles conversion where the UI accepts or shows lb / ft-in.
2. **History (`REQ-WGT-003`):** **`GET /weight_logs`** lists the signed-in user’s logs with that ordering. **`WeightLogs::HistoryPage`** applies **30 rows per page** and the **`page`** query param (offset/limit on the ordered scope). Columns: local **`logged_at`**, weight, height snapshot, BMI, and a **Delete** link per row. **Presentation** of weight and height snapshot respects **`User#body_unit_system`** while rows stay canonical (**REQ-WGT-004**).
3. **Delete:** **`GET /weight_logs/:id/confirm_destroy`** (warning) → **`DELETE /weight_logs/:id`** via **`WeightLogs::DestroyLog`** (transaction: **`destroy!`** the log, then **`ReconcileUserCurrentStats`**). Scoped to **`Current.user.weight_logs`**; other users’ IDs → **404**.
4. **Navigation:** Home and profile expose links to history and the entry form (`REQ-WGT-002`).

### 1.10 Informes / reporting (read only, `REQ-RPT-001`–`003`)

1. **Browser** requests **`GET /informes`** with optional **`fecha`** (ISO date), same validity rules as Mi Día (not after local today; invalid → redirect + flash).
2. **`ReportsController#show`** delegates assembly to **`Reports::ShowPage`**, which runs entirely **read-only** (no writes to `HabitCompletion`, `WeightLog`, or habits).
3. **`Reports::CalendarPeriodBounds`** returns the **Monday–Sunday** week range and **civil month** range that contain the reference local date (user IANA timezone).
4. **Completions preload:** one **`HabitCompletion`** query spans from **`min`**(each habit’s streak lower bound, start of the combined week/month window) through **`max`**(end of that window, reference date), grouped by `user_habit_id` and indexed by `completed_on` — used both for fulfillment slices and for streak walks (`REQ-RPT-001` / `REQ-RPT-002`).
5. **Fulfillment:** for each `UserHabit`, **`Habits::FulfillmentForPeriod`** runs on the week slice and month slice (via **`Habits::DueOnDate`**, including **`schedule_only:`** for inactive habits with activity in-range per **REQ-RPT-001**). Rows are omitted when both week and month stats are absent.
6. **Streaks:** habits **inactive** with **no** completion in the **union** of that week and month are **omitted** from the streak table; for each remaining habit, **`Habits::ReportCurrentStreak`** (wraps **`Habits::Streak`**) and **`Habits::LongestStreak`** consume the preloaded completion map from each habit’s lower bound through **`as_of`**.
7. **Weight chart (`REQ-RPT-003`):** **`WeightLogs::ChartSeries`** loads the user’s full ordered `weight_logs` projection (not **`WeightLogs::HistoryPage`** pagination); the view renders server-side SVG (helper), axis labels in user TZ like history. **Y-axis, legend, and tooltips** use the same **`User#body_unit_system`** as elsewhere (**REQ-PROF-003**, **REQ-WGT-004**); the polyline still reflects canonical **`weight_kg`** values.

## 2. Cascading side effects and invariants

| Trigger | Required behavior | Mechanism |
|--------|-------------------|-----------|
| User signs in | Default categories/habits provisioned idempotently | `ProvisionDefaultHabitsJob` (see Phase 2 habits core) |
| At least one **`HabitCompletion`** exists for a **`UserHabit`** | **`activation_date`** must not change on update | Model validation on `UserHabit` |
| **`HabitCompletion`** create/update | Habit must be **active** | Model validation on `HabitCompletion` |
| User marks **inactive** habit | Completion writes rejected | Service + controller flash |
| **`MenuEntry`** save | **`Dish`** (if present) must belong to same user as menu; freeform gated by **`allow_menu_freeform`** | Model + **`Menus::UpsertEntry`** |
| **`PhaseAssignment`** save | Week ranges for a user must not overlap | Model validation |
| **`ExerciseRoutineAssignment`** save | Week ranges for a user must not overlap **among routine assignments** (separate from menu ranges) | Model validation |
| **`Programs::ApplyBundleToUser`** | Replaces **all** of the user’s **`phase_assignments`** and **`exercise_routine_assignments`** with rows derived from a owned **`PhaseProgram`**’s segments | Service (single transaction) |
| **`PhaseProgram`** save or **`PhaseProgramAssignment`** commit | If a **`catalog_listing_facets`** row exists for that program, **`duration_weeks_min`** / **`duration_weeks_max`** reflect **min** `start_week` and **max** `end_week` on **`phase_program_assignments`** (or **NULL** if none) | **`Catalog::MaterializePhaseProgramFacetDuration`** (**REQ-CAT-001**) |
| **Confirmed delete** of **`ExerciseRoutine`** with assignments | All **`exercise_routine_assignments`** for that routine removed, then routine deleted | **`ExerciseRoutines::DestroyRoutine`** (transaction) |
| **`WeightLog`** create or delete | **`User#current_weight_kg`** / **`current_bmi`** reflect latest row by **`logged_at`** (or **`nil`** if none) | HTTP create: **`WeightLogs::LoggedAtParamParser`** then **`LogWeightService`** + **`WeightLogs::ReconcileUserCurrentStats`**; delete: **`WeightLogs::DestroyLog`** |
| **`GET /informes`** | **Read-only**; must not create/update/delete domain rows | **`Reports::ShowPage`** + query objects only |
| Phase-start **reminder** sweep | At most one logical send per `(user, kind, local_date)` | Unique index on **`phase_reminder_events`** |
| Per-habit **reminder** sweep | At most one logical processing attempt per `(user, user_habit, local_date)` | Unique index on **`habit_reminder_events`** |

## 3. Caching invalidation

- **Mi Día — streak map (`REQ-DAY-004`):** **`Habits::MiDayStreakPrefetch`** stores the per-request `user_habit_id → streak_count` map in **`Rails.cache`**. The cache key includes the user id, the selected local date, and **`user_habits.id` + `updated_at`** tuples for the due habits (see §1.1). **`Habits::RecordCompletion`** and **`Habits::ClearCompletion`** **`touch`** the parent **`UserHabit`** on success so `updated_at` advances and stale streak maps are not reused after writes (§1.2, §1.3).
- **Elsewhere:** no additional application-cache strategy for Mi Día page HTML or habit lists; responses remain full server-render per request unless fragment/HTTP caching is introduced later.
