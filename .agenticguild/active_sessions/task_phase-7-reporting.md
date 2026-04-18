% Task: phase-7-reporting
% Goal: Ship Phase 7 from `docs/ROADMAP.md` — habit fulfillment reporting (REQ-RPT-001), streak reporting (REQ-RPT-002), weight progress chart (REQ-RPT-003), aligned with `docs/core/SYSTEM_ARCHITECTURE.md` (Rails + Hotwire + SQLite, thin controllers + services, I18n).

---

## Scope (from roadmap)

| # | Item | REQ | Depends on |
|---|------|-----|------------|
| 25 | Habit completion report: fulfillment % per habit, weekly + monthly breakdown | REQ-RPT-001 | Phase 3 |
| 26 | Streak report: current + all-time longest per habit | REQ-RPT-002 | Phase 3 #14 |
| 27 | Weight progress chart: visual trend over time | REQ-RPT-003 | Phase 6 |

**SPEC note:** `REQ-RPT-001`–`003` are registered as a single row in `docs/core/SPEC.md` (planned); detailed acceptance criteria should be expanded in SPEC during this phase for traceability.

---

## Discovery Log

### Architectural anchors (non-negotiable from existing system)

- **Timezone:** All calendar semantics for the user use **`Current.user` IANA timezone** (same as Mi Día, streaks).
- **Due vs completion:** Reporting for habits must align with **`Habits::DueOnDate`** (due days) and **`HabitCompletion`** (`done` / `failed` / absent). Streak semantics are defined in **REQ-DAY-004** and implemented in **`Habits::Streak`** (current streak only today).
- **Inactive habits (locked):** In reports, **include an inactive habit** only if it has at least one completion (or relevant record) **in the queried period**. If it has **no** completions/activity in that period, **do not show** that habit row for that period.
- **Performance:** `docs/ROADMAP.md` backlog flags **materializing** streak metrics if live history walks are slow; measure after Phase 7 implementation — **not** a prerequisite to ship REQ-RPT-002.

### Decisions locked (product)

1. **Week boundaries:** **Monday–Sunday** (user local week), in the user’s IANA timezone.
2. **Month boundaries:** **Civil calendar month** (1st through last day of month) in the user’s timezone.
3. **Streak report `as_of`:** **Parity with Mi Día** — same date selection rules (local date param / max today / no future), same TZ.
4. **Fulfillment %:** Denominator = **due days** in the chosen period; numerator = **done**; `failed` and absent row both count as **not** fulfilled (aligned with REQ-DAY-004 / streak semantics).

### Navigation (locked)

- **Opción A — Una sola zona “Informes”:** Una **única ruta** (p. ej. `GET /informes`) con **pestañas o secciones** (Turbo Frames o anclas) para cumplimiento, rachas y peso; sin tres URLs hermanas para cada informe.

### Weight chart — loading (locked: perceived performance)

- **Objetivo:** Que el usuario **no espere** de forma perceptible: una **sola** consulta acotada al usuario, usando el **índice existente** (`user_id` + `logged_at` como en REQ-WGT-001), proyectando solo columnas necesarias para el gráfico (`logged_at`, `weight_kg`, etc.).
- **No** reutilizar la paginación del listado del historial; **no** N+1.
- **Serie por defecto:** Todo el historial del usuario en BD salvo que el volumen sugiera un tope razonable documentado en implementación (p. ej. límite alto o downsampling solo si hace falta — decidir en código con comentario y test si se aplica tope).
- **Render:** Preferir **servidor primero** (SVG/polyline o tabla de puntos + CSS) o Stimulus mínimo; evitar bundles pesados (alineado a SYSTEM_ARCHITECTURE).

### Risks & dark corners

| Risk | Mitigation idea |
|------|----------------|
| **Longest streak** requires scanning history (or storing aggregates) | Reuse `DueOnDate` + completions; consider extracted service `Habits::LongestStreak` mirroring `Streak` walk pattern; watch `MAX_CALENDAR_DAY_STEPS`-class limits. |
| **Fulfillment** over large intervals with sparse due days (e.g. monthly habit) | % still valid but UX may need “N/M due days” not just %. |
| **Chart without Node bundler** | Prefer minimal JS (Stimulus + SVG/canvas) or server-rendered sparkline; avoid introducing Webpack/Vite without ADR. |
| **Double-counting** | One completion row per `(user_habit, completed_on)` — already enforced. |

### Common implementation mistakes to avoid

- Mixing **UTC** dates with **user-local** dates when aggregating weeks/months.
- Using **calendar** streak logic inconsistent with **REQ-DAY-004** (closed “today” rules, non-due days skipped).
- Chart that ignores **timezone** on `WeightLog#logged_at` (use same parsing/display approach as **`WeightLogs::HistoryPage`** / **`LoggedAtParamParser`** family).

---

## Domain Model (CbC — approved)

**Status:** Confirmed by user — 2026-04-17.

### Entities / responsibilities

- **FulfillmentPeriod** (conceptual) — A bounded local date range (week or month) for aggregation; boundaries computed in user TZ.
- **HabitFulfillmentStats** — Per `UserHabit`, counts: due days in range, done days, derived percentage.
- **StreakSnapshot** — Per `UserHabit`: current streak (as-of date), longest streak (all-time per REQ-RPT-002). *Longest is not yet a first-class persisted entity.*
- **WeightTrendSeries** — Ordered `(time, weight_kg)` (and optional BMI) for chart; scoped to user.

### Invariants

- Fulfillment **denominator** counts only days where **`DueOnDate.due_on?`** is true within the range.
- Fulfillment **numerator** counts due days with completion **`status == "done"`**.
- Streak report **current** value must match **`Habits::Streak`** for the same `as_of` as Mi Día’s selected local date.
- Longest streak uses the **same** due/done/failed rules as REQ-DAY-004 over the habit’s schedulable history.

### Value objects / branded types

- **`LocalDateRange`** — Start/end `Date` in user zone, validated `start <= end`.
- **`FulfillmentRatio`** — Rational or fixed decimal derived from counts; avoid raw float percentages without defining rounding (e.g. 1 decimal vs integer %).

---

## Working notes

- **REQ-RPT-002 longest streak vs backlog:** Phase 7 **must** implement **all-time longest streak** (computation in a service, e.g. `Habits::LongestStreak` or equivalent). The ROADMAP **backlog** item (“materializar racha… si el cálculo en vivo es lento”) is an **optional optimization later**, not the solution that delivers REQ-RPT-002. If profiling shows pain, add persisted counters/columns in a follow-up.
- After acceptance criteria are written into SPEC for REQ-RPT-001–003, add `# [REQ-RPT-…]` comments per traceability rules.

---

## Implementation plan

Locked execution contract for `start-task` (TDD-first feature work).

<implementation_plan>
  <classification>Feature</classification>
  <roadmap_phase>Phase 7 — Reporting</roadmap_phase>

  <step id="1" status="complete">
    Expand docs/core/SPEC.md: split REQ-RPT-001, REQ-RPT-002, REQ-RPT-003 into explicit rows with acceptance criteria reflecting locked decisions (week Mon–Sun, civil month in user TZ, inactive habits visibility rule, Mi Día parity for streak as_of, weight chart query vs list pagination). Keep aligned with docs/core/SYSTEM_ARCHITECTURE.md.
  </step>

  <step id="2" status="complete">
    TDD — Period boundaries: Write failing specs for a service or module (e.g. under Reports:: or Habits::) that, given a user timezone and a reference local Date, returns the inclusive Date range for (a) the Monday–Sunday week containing that date, and (b) the civil month containing that date. Implement until green. Preconditions: valid IANA zone. Postconditions: start less than or equal to end; boundaries are user-local dates.
  </step>

  <step id="3" status="pending">
    TDD — REQ-RPT-001 fulfillment: Write failing specs for Habits::FulfillmentForPeriod (or equivalent) that, for a UserHabit and inclusive local Date range, returns due_count, done_count, and derived percentage using Habits::DueOnDate and HabitCompletion (done only counts toward numerator; failed and absent do not). Cover inactive habits: omitted when no completion in range; included when at least one completion exists in range. Implement until green.
  </step>

  <step id="4" status="pending">
    TDD — REQ-RPT-002 longest streak: Write failing specs for Habits::LongestStreak (or equivalent) that computes all-time longest run of consecutive due days each marked done, per REQ-DAY-004 (aligned with Habits::Streak for closed days and non-due skipping). Reuse or mirror completion prefetch patterns from Habits::Streak / MyDayController; respect lower_bound and activation rules. Implement until green. Do not add persisted streak columns in this phase (backlog optimization only).
  </step>

  <step id="5" status="pending">
    TDD — REQ-RPT-002 current streak: Specs proving the report current streak equals Habits::Streak.call for the same user_habit, as_of, and preloaded completions_by_date, with the same date param rules as Mi Día. Avoid N+1 in controller or orchestrating service.
  </step>

  <step id="6" status="pending">
    TDD — REQ-RPT-003 weight series: Write failing specs for a service (e.g. WeightLogs::ChartSeries) that returns all weigh-ins for the user in one indexed query on user_id and logged_at, ordered ascending, minimal columns. Do not use WeightLogs::HistoryPage pagination. Implement until green.
  </step>

  <step id="7" status="pending">
    Integration — Informes UI: Single route GET /informes (Spanish path consistent with mi_dia), one controller action, one page with tabs or sections for fulfillment, streaks, and weight without separate top-level routes per tab. Request or system specs for auth, render, section visibility. I18n for all user-visible strings (es default, en).
  </step>

  <step id="8" status="pending">
    Presentation: Weight trend via server-first SVG or polyline or equivalent lightweight markup; axis and labels respect user timezone for logged_at display, consistent with existing weight history.
  </step>

  <step id="9" status="pending">
    Traceability and navigation: Add REQ-RPT comment anchors per project rules; link to /informes from home or primary nav. Full test suite green.
  </step>
</implementation_plan>
