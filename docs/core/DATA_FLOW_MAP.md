# Data Flow & Side-Effect Map

**Purpose:** Maps how entities mutate and propagate throughout the system. AI agents must consult this document to ensure they do not orphan data or bypass necessary side-effects.

## 1. Primary data flows

### 1.1 Mi Día (read)

1. **Browser** requests `GET /mi_dia` with optional `fecha` (ISO date, user-local calendar day).
2. **`MyDayController#show`** resolves “today” and the selected day in the user’s **current** IANA timezone; rejects future dates and invalid `fecha`.
3. **`Habits::DueHabitsForDay`** loads active `UserHabit` rows for the user and filters to habits **due** on that civil date via **`Habits::DueOnDate`** (inactive habits never appear).
4. **`HabitCompletion`** rows for `(user_habit_id ∈ due habits, completed_on = selected day)` build the per-habit done/failed/pending UI state (pending = no row).
5. **`Habits::Streak`** computes the displayed streak per due habit for that day; the controller may pass preloaded completion rows for the walk window to avoid N+1 queries.

### 1.2 Mark done / failed (write)

1. **Browser** submits `POST /habit_completions` with `user_habit_id`, `completed_on`, `status` (`done` or `failed`).
2. **`HabitCompletionsController`** scopes the habit to **`Current.user`**, parses the local date, and calls **`Habits::RecordCompletion`**.
3. **`Habits::RecordCompletion`** enforces: owner, habit active, date not in the future, date is a **due** day per `DueOnDate`, status allowed; then **`find_or_initialize_by`** `(user_habit, completed_on)` and saves **`HabitCompletion`** (unique per day per habit).
4. **Redirect** back to Mi Día (with `fecha` preserved for past days).

### 1.3 Clear → pending (delete)

1. **Browser** submits `DELETE /habit_completions/:id`.
2. Controller loads the row through a join scoped to **`Current.user`**.
3. **`Habits::ClearCompletion`** verifies owner and active habit, then **`destroy!`** the row (pending = no row).

## 2. Cascading side effects and invariants

| Trigger | Required behavior | Mechanism |
|--------|-------------------|-----------|
| User signs in | Default categories/habits provisioned idempotently | `ProvisionDefaultHabitsJob` (see Phase 2 habits core) |
| At least one **`HabitCompletion`** exists for a **`UserHabit`** | **`activation_date`** must not change on update | Model validation on `UserHabit` |
| **`HabitCompletion`** create/update | Habit must be **active** | Model validation on `HabitCompletion` |
| User marks **inactive** habit | Completion writes rejected | Service + controller flash |

## 3. Caching invalidation

- **Strategy:** None at the application cache layer for Mi Día in the current stack; pages are server-rendered per request.
- **Critical nodes:** N/A until fragment or HTTP caching is introduced for Mi Día or habit lists.
