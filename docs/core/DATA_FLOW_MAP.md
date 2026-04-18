# Data Flow & Side-Effect Map

**Purpose:** Maps how entities mutate and propagate throughout the system. AI agents must consult this document to ensure they do not orphan data or bypass necessary side-effects.

## 1. Primary data flows

### 1.1 Mi Día (read)

1. **Browser** requests `GET /mi_dia` with optional `fecha` (ISO date, user-local calendar day).
2. **`MyDayController#show`** resolves “today” and the selected day in the user’s **current** IANA timezone; rejects future dates and invalid `fecha`.
3. **`Habits::DueHabitsForDay`** loads active `UserHabit` rows for the user and filters to habits **due** on that civil date via **`Habits::DueOnDate`** (inactive habits never appear).
4. **`HabitCompletion`** rows for `(user_habit_id ∈ due habits, completed_on = selected day)` build the per-habit done/failed/pending UI state (pending = no row).
5. **`Habits::Streak`** computes the displayed streak per due habit for that day; the controller may pass preloaded completion rows for the walk window to avoid N+1 queries.
6. **Exercise context (REQ-EXR-003):** **`Phases::WeekNumber.for_local_date`** yields the program week index (or nil if no anchor / before anchor). **`ExerciseRoutines::ResolveActiveRoutine`** returns the routine mapped to that week via **`exercise_routine_assignments`**, independent of menu assignments.
7. **Ejercicio habit:** the `UserHabit` joined to **`global_habit_templates.code == "fitness_exercise"`** is loaded separately when needed (e.g. inactive habit not in the due list). Inline routine preview on Mi Día appears only when that habit is **due** and **active**; a global shortcut to **`/exercise_routines`** and **`/phase`** is always shown.

### 1.2 Mark done / failed (write)

1. **Browser** submits `POST /habit_completions` with `user_habit_id`, `completed_on`, `status` (`done` or `failed`).
2. **`HabitCompletionsController`** scopes the habit to **`Current.user`**, parses the local date, and calls **`Habits::RecordCompletion`**.
3. **`Habits::RecordCompletion`** enforces: owner, habit active, date not in the future, date is a **due** day per `DueOnDate`, status allowed; then **`find_or_initialize_by`** `(user_habit, completed_on)` and saves **`HabitCompletion`** (unique per day per habit).
4. **Redirect** back to Mi Día (with `fecha` preserved for past days).

### 1.3 Clear → pending (delete)

1. **Browser** submits `DELETE /habit_completions/:id`.
2. Controller loads the row through a join scoped to **`Current.user`**.
3. **`Habits::ClearCompletion`** verifies owner and active habit, then **`destroy!`** the row (pending = no row).

### 1.4 Menu grid slot (read + write via Turbo)

1. **Browser** loads `GET /menus/:id/edit`; controller builds a sparse map of `menu_entries` keyed by `(weekday, meal_type)` and renders the grid partials.
2. **Create/update slot:** `POST /menus/:menu_id/menu_entries` with Turbo; **`Menus::UpsertEntry`** validates ownership, meal type, weekday, user freeform preference, and recipe ownership; creates/updates/destroys **`MenuEntry`** as needed.
3. **Response:** `turbo_stream.replace` for the slot frame only (partial `menus/slot`).
4. **Clear slot:** `DELETE .../menu_entries/clear` removes the row if present; same Turbo replace with empty slot.

### 1.5 Phase plan (anchor, assignments, active menu + routine)

1. **Browser** loads `GET /phase`; **`PhasesController`** sets `week_index` via **`Phases::WeekNumber.today_for`**, resolves **`Phases::ResolveActiveMenu`** and **`ExerciseRoutines::ResolveActiveRoutine`**, loads ordered **`phase_assignments`** and **`exercise_routine_assignments`**, and computes in-app reminder visibility and **two** “plan ended” flags via **`Phases::PhaseStartInAppReminderVisible`**, **`Phases::PlanEnded`** (menu lane), and **`ExerciseRoutines::PlanEnded`** (routine lane).
2. **Patch anchor / reminder prefs:** `PATCH /phase` updates **`User`** (`phase_one_starts_on`, reminder booleans); may set flash **notice** and **alert** when anchor is more than three local days ahead.
3. **Menu assignments CRUD:** **`PhaseAssignmentsController`**, scoped to **`Current.user`**; overlaps rejected at validation.
4. **Routine assignments CRUD:** **`ExerciseRoutineAssignmentsController`**, scoped to **`Current.user`**; overlaps rejected among **routine** assignments only.
5. **Plan extension (menus):** **`Phases::RepeatLastPhaseAssignment`** duplicates the last contiguous menu assignment block forward when the user confirms.
6. **Plan extension (routines):** **`ExerciseRoutines::RepeatLastAssignment`** duplicates the last contiguous **routine** assignment block forward when the user confirms.

### 1.6 Exercise routines (CRUD, duplicate, destroy)

1. **Browser** uses **`ExerciseRoutinesController`** for list/create/edit/update; **`POST …/duplicate`** copies structure to a new routine.
2. **Destroy with assignments:** **`GET …/confirm_destroy`** warns that week-range rows will be removed; confirming invokes **`ExerciseRoutines::DestroyRoutine`**, which deletes all **`exercise_routine_assignments`** for that routine then the **`exercise_routine`** in one transaction.

### 1.7 Phase-start reminders (async)

1. **Solid Queue** runs **`Phases::SweepPhaseStartRemindersJob`** on the schedule in **`config/recurring.yml`**.
2. For each user whose **local today** is a phase-start day and prefs allow, **`Phases::ProcessPhaseStartReminderForUser`** creates idempotent **`PhaseReminderEvent`** rows and sends mail when email is enabled.
3. **In-app banner:** rendered on **`PhasesController#show`** when an event applies and the user has not dismissed for that local day (`phase_reminder_dismissed_on`); **`POST /phase/dismiss_reminder`** sets dismissal to local today.

### 1.8 Weight log (create, list, delete, reconcile)

1. **Entry form (`REQ-WGT-002`):** **`GET /weight_logs/new`** → **`POST /weight_logs`** with **`weight_kg`** and **`logged_at`** (datetime-local string). **`WeightLogs::LoggedAtParamParser`** turns the raw field into a **`Time`** in the user’s **IANA timezone** (blank input → **`Time.current`**; invalid parse → validation error on **`logged_at`**). Height is **not** edited on this form; each persisted row snapshots **`User#height_cm`** at save time. **`LogWeightService`** creates **`WeightLog`** (BMI computed on the model) inside a transaction, then **`WeightLogs::ReconcileUserCurrentStats`**, which sets **`users.current_weight_kg`** and **`users.current_bmi`** from the **`WeightLog`** row with **maximum `logged_at`** (tie-break **`id` DESC**), or **`nil`** if no logs remain. A **retroactive** `logged_at` must not overwrite “current” if a newer weigh-in already exists.
2. **History (`REQ-WGT-003`):** **`GET /weight_logs`** lists the signed-in user’s logs with that ordering. **`WeightLogs::HistoryPage`** applies **30 rows per page** and the **`page`** query param (offset/limit on the ordered scope). Columns: local **`logged_at`**, weight, height snapshot, BMI, and a **Delete** link per row.
3. **Delete:** **`GET /weight_logs/:id/confirm_destroy`** (warning) → **`DELETE /weight_logs/:id`** via **`WeightLogs::DestroyLog`** (transaction: **`destroy!`** the log, then **`ReconcileUserCurrentStats`**). Scoped to **`Current.user.weight_logs`**; other users’ IDs → **404**.
4. **Navigation:** Home and profile expose links to history and the entry form (`REQ-WGT-002`).

## 2. Cascading side effects and invariants

| Trigger | Required behavior | Mechanism |
|--------|-------------------|-----------|
| User signs in | Default categories/habits provisioned idempotently | `ProvisionDefaultHabitsJob` (see Phase 2 habits core) |
| At least one **`HabitCompletion`** exists for a **`UserHabit`** | **`activation_date`** must not change on update | Model validation on `UserHabit` |
| **`HabitCompletion`** create/update | Habit must be **active** | Model validation on `HabitCompletion` |
| User marks **inactive** habit | Completion writes rejected | Service + controller flash |
| **`MenuEntry`** save | Recipe (if present) must belong to same user as menu; freeform gated by **`allow_menu_freeform`** | Model + **`Menus::UpsertEntry`** |
| **`PhaseAssignment`** save | Week ranges for a user must not overlap | Model validation |
| **`ExerciseRoutineAssignment`** save | Week ranges for a user must not overlap **among routine assignments** (separate from menu ranges) | Model validation |
| **Confirmed delete** of **`ExerciseRoutine`** with assignments | All **`exercise_routine_assignments`** for that routine removed, then routine deleted | **`ExerciseRoutines::DestroyRoutine`** (transaction) |
| **`WeightLog`** create or delete | **`User#current_weight_kg`** / **`current_bmi`** reflect latest row by **`logged_at`** (or **`nil`** if none) | HTTP create: **`WeightLogs::LoggedAtParamParser`** then **`LogWeightService`** + **`WeightLogs::ReconcileUserCurrentStats`**; delete: **`WeightLogs::DestroyLog`** |
| Phase-start **reminder** sweep | At most one logical send per `(user, kind, local_date)` | Unique index on **`phase_reminder_events`** |

## 3. Caching invalidation

- **Strategy:** None at the application cache layer for Mi Día in the current stack; pages are server-rendered per request.
- **Critical nodes:** N/A until fragment or HTTP caching is introduced for Mi Día or habit lists.
