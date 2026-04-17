% Task: phase-5-exercise-routines
% Scope: Full Phase 5 (ROADMAP #20–#22) — REQ-EXR-001 … REQ-EXR-005
% Confirmed: 2026-04-17 — entire Phase 5 arc; SPEC locked with decisions log; Q11/Q12 updated per product

---

## Goal (from roadmap + SPEC)

1. **REQ-EXR-001** — Exercise routine model: ordered lines per weekday; not globally empty; CRUD + duplicate; delete with **warning** then **auto-remove** week-range assignments, then routine (transactional).
2. **REQ-EXR-002** — Week-range assignments for routines (same anchor / `Phases::WeekNumber` as menus); non-overlapping routine ranges; resolve active routine; **integrated on `/phase`**.
3. **REQ-EXR-003** — Mi Día: Ejercicio `fitness_exercise` when due; global shortcut always; inactive habit → disabled block; day preview + full week link; Turbo; home/nav entry points.
4. **REQ-EXR-004** — **Parity REQ-MENU-004** for the routine lane: shared anchor warning; phase-start reminders coherent; `/phase` surfaces **both** menu and routine lanes.
5. **REQ-EXR-005** — **Parity REQ-MENU-005** for routines: `PlanEnded` for routine assignments; extension prompt; **RepeatLast**-style service for routine ranges.

**Out of Phase 5 (backlog):** public sharing of routines (Q8) — `docs/ROADMAP.md` Backlog.

---

## Architectural alignment (`docs/core/SYSTEM_ARCHITECTURE.md`)

- **Server-rendered + Turbo**; thin controllers; services under `app/services/exercise_routines/` (and extend `Phases::*` where the phase plan is shared).
- **Reuse** `User#phase_one_starts_on`, **`Phases::WeekNumber`**, mirror **`Phases::ResolveActiveMenu`** → **`ExerciseRoutines::ResolveActiveRoutine`** (or `Phases::ResolveActiveExerciseRoutine` if colocated).
- **Ejercicio** linkage via **`GlobalHabitTemplate#code == "fitness_exercise"`** only.
- **I18n** `es` / `en`; `# [REQ-EXR-…]` traceability.
- Update **`docs/core/SCHEMA_REFERENCE.md`**, **`docs/core/DATA_FLOW_MAP.md`** after schema and flows.

---

## Domain Model

**Approved:** 2026-04-17 (start-task step 3.0). Locked for Phase 5 implementation.

| Concept | Implementation shape |
|--------|----------------------|
| **ExerciseRoutine** | `ApplicationRecord`; `belongs_to :user`; unique `name` scoped to user (Menu parity); invariant: not globally empty (≥1 line on ≥1 weekday); destroy only after dependent routine week-range rows removed in one transaction (service). |
| **ExerciseRoutineLine** | `belongs_to :exercise_routine`; `weekday` integer 0–6; `position` unique per `(exercise_routine, weekday)`; label/notes with migration-defined string limits. |
| **ExerciseRoutineAssignment** | Same structural role as menu `PhaseAssignment` for routines: `user_id`, `exercise_routine_id`, `start_week`, `end_week`; no overlap among a user’s routine assignments; independent from menu phase assignments. |
| **Parity services** | `ExerciseRoutines::PlanEnded`, `ExerciseRoutines::RepeatLastAssignment` (REQ-EXR-005). |

Detailed CbC narrative remains in **Domain model (CbC)** below.

---

## Domain model (CbC)

### **ExerciseRoutine**

- **Responsibility:** User-owned named weekly container; ordered lines grouped by weekday.
- **Invariants:** Belongs to `User`; name uniqueness **like `Menu`**; **not** globally empty (≥1 line on ≥1 weekday).
- **Destroy:** User may confirm delete; **dependent routine week-range assignments** removed **first** (after explicit warning in UI), then routine — transactional service (e.g. `ExerciseRoutines::DestroyRoutine`).

### **ExerciseRoutineLine** (or equivalent)

- **Responsibility:** One ordered row: `(routine, weekday, position)` with label/notes per implementation.
- **Invariants:** `weekday` 0..6; `position` unique per `(routine, weekday)`; reasonable length limits.

### **ExerciseRoutineAssignment** (table name TBD)

- **Responsibility:** Same as `PhaseAssignment` shape but points to `ExerciseRoutine`; `user_id`, `start_week`, `end_week`; no overlap with **sibling routine assignments** (same validation pattern as `PhaseAssignment`).
- **Independence:** Menu `phase_assignments` unchanged; same `week_index` can resolve menu + routine.

### **Parity services (REQ-EXR-005)**

- **`ExerciseRoutines::PlanEnded`** (or name aligned with `Phases::PlanEnded`) — `week_index > max(end_week)` on **routine** assignments only.
- **`ExerciseRoutines::RepeatLastAssignment`** — mirror **`Phases::RepeatLastPhaseAssignment`** for routine table.

### **Parity reminders (REQ-EXR-004)**

- Reuse **`Phases::SweepPhaseStartRemindersJob`** / **`PhaseReminderEvent`** where the phase start is **one** anchor; extend **`PhasesController#show`** (and mailer copy if needed) so **routine** lane status is visible alongside menu (no “menu-only” mental model).

---

## Product decisions (locked — see SPEC Decisions log)

- Ordered list per weekday; not totally empty routine; global Mi Día shortcut; inline habit block only when due; inactive habit UI disabled; assignments on `/phase`; duplicate routine; name = menus; home/nav links; **Q11** menu parity for alerts + plan end; **Q12** confirm delete + cascade assignments in DB transaction.

---

## Edge cases / pitfalls

| Topic | Mitigation |
|--------|------------|
| Delete + assignments | Single transaction; warning lists count of ranges to remove. |
| Two `PlanEnded` booleans | `@menu_plan_ended` vs `@routine_plan_ended` on `PhasesController` — independent max `end_week` per table. |
| Phase start reminder email | One anchor day — body may mention both lanes if both configured. |
| Repeat last (routines) | Same edge cases as `RepeatLastPhaseAssignment` (no rows → nil). |

---

## Discovery deep-dive — REQ-EXR-005 (explore-task, parity REQ-MENU-005)

### Reference implementation (menus)

- **`Phases::PlanEnded`**: `false` if `week_index` blank; `false` if no `phase_assignments` (`maximum(:end_week)` nil); else `week_index > max_end`. Boundary: week **equal** to `max_end` → **not** ended.
- **`Phases::RepeatLastPhaseAssignment`**: finds assignment with `order(end_week: :desc, start_week: :desc).first`, computes span, appends `[max_end+1, max_end+span]` with same `menu_id`. Returns `nil` if no assignments → controller shows “nothing to repeat” alert.
- **UI**: `GET /phase` sets `@plan_ended`; banner `data-test="phase-plan-ended-banner"` + `repeat_last_assignment_phase_path` POST + link `new_phase_assignment_path`.

### REQ-EXR-005 — extra edge cases / dark corners

| Situation | Expected behavior (SPEC + parity) |
|-----------|-------------------------------------|
| **No routine assignments** | `ExerciseRoutines::PlanEnded` → **false** (same as no menu assignments). No routine “plan ended” banner; empty lane is a different UX than “past all ranges”. |
| **User in a gap** (e.g. ranges 1–4 and 8–10; current week 6) | **Not** ended: `week_index > max_end` is false. User may see “no active routine for this week” elsewhere, but **not** the extension prompt until week > 10. |
| **Menu ended, routine not** (or inverse) | Two independent `max(end_week)` queries. Show **only** the banner(s) that apply; copy must name **routine** vs **menu** so users are not confused. |
| **Both lanes ended** | Two banners or one composite card with two sub-actions — product choice; tests should assert both CTAs exist and hit the correct routes (`repeat_last` menu vs routine, new range links). |
| **`week_index` blank** (`Phases::WeekNumber.today_for` nil) | Mirror `PlanEnded`: treat routine plan as **not** ended for this predicate (avoid raising or showing a misleading “extend” CTA). |
| **Repeat last after concurrent edits** | Same race as menus: two tabs could append twice; acceptable unless product asks idempotency (not in SPEC). |
| **Last routine block deleted but older ranges remain** | Unlikely if FK prevents; if assignments always point at existing routines, deleting a routine cascades or blocks — align with Q12 destroy flow. |

### Common implementation mistakes to avoid

1. **Reusing `@plan_ended` for both lanes** — would hide one lane’s extension state. Use explicit `@menu_plan_ended` / `@routine_plan_ended` (or equivalent) and separate I18n keys for routine copy.
2. **Using `>=` instead of `>` for “past all ranges”** — breaks the week that equals `max_end` (must still be “inside” the plan).
3. **Querying `phase_assignments` for routine logic** — routine ended must use **routine assignment** table only.
4. **Repeat-last picking the wrong row** — mirror `order(end_week: :desc, start_week: :desc)` so the canonical “last block” matches menu semantics when multiple ranges exist (non-overlapping implies a unique max `end_week`, but order is still explicit).
5. **Single global `repeat_last_assignment` route** — may need **`repeat_last_routine_assignment`** (or namespaced param) so POST targets the correct service; avoid one action that repeats “both” unless SPEC requires it (it does not — lane-specific parity).

### Open questions (low severity — SPEC is largely sufficient)

- **Banner stacking**: If both menus and routines are ended, prefer two slim banners vs one merged panel — **implementation detail**; keep accessibility (`aria-live`, distinct `data-test` for system specs).
- **“Add new range” for routines**: Confirm link target is the **new routine assignment** path (parity with `new_phase_assignment_path` for menus) once routes exist.

---

## Readiness

SPEC updated (`REQ-EXR-001`–`005`). Backlog row for MENU-004/005 parity **removed** from ROADMAP (now in scope). Implementation plan below is **locked** for **start-task**.

<implementation_plan>
  <classification>Feature</classification>
  <tdd_mandate>Every behavior-bearing change is driven by a failing spec first (model, request, service, or system as appropriate), then implemented, then refactored.</tdd_mandate>

  <step id="1" status="complete">Write failing specs for `ExerciseRoutine` and `ExerciseRoutineLine` (or chosen names): user ownership, name normalization/uniqueness like `Menu`, ordered lines per weekday, validation that the routine cannot be saved completely empty, line limits consistent with migrations. Add migrations and models; factory traits; make specs green. Tag examples with `# [REQ-EXR-001]`.</step>

  <step id="2" status="complete">Write failing specs for the routine week-range assignment model: `start_week`/`end_week`, overlap validation mirroring `PhaseAssignment` (including unsaved-record case), `user_id` + routine ownership. Migration + model; green. `# [REQ-EXR-002]`.</step>

  <step id="3" status="complete">Write failing specs for `ExerciseRoutines::ResolveActiveRoutine` (and any week-index helper) mirroring `Phases::ResolveActiveMenu`. Implement service; green. `# [REQ-EXR-002]`.</step>

  <step id="4" status="complete">Write failing request/system specs for exercise routine CRUD (scoped to `Current.user`), **duplicate** routine, and **destroy** flow: first request shows warning/confirmation; confirming deletes **all** `ExerciseRoutineAssignment` rows for that routine then the routine in one transaction. Implement controller + `ExerciseRoutines::DestroyRoutine` (or equivalent). I18n for warnings. Green. `# [REQ-EXR-001]`.</step>

  <step id="5" status="complete">Write failing specs for `ExerciseRoutines::PlanEnded` and `ExerciseRoutines::RepeatLastAssignment` mirroring `Phases::PlanEnded` / `Phases::RepeatLastPhaseAssignment`. Integrate on `PhasesController#show`: assign `@routine_plan_ended`, extension UI for routine lane, routes/actions analogous to menu extension. Green. `# [REQ-EXR-005]`.</step>

  <step id="6" status="complete">Write failing specs for REQ-EXR-004 parity: `/phase` renders routine assignment summary alongside menu; anchor PATCH still flashes &gt;3-day warning for shared anchor (existing behavior); ensure phase-start reminder visibility path accounts for routine lane (extend `PhaseStartInAppReminderVisible` or template sections as needed). Adjust mailer/view copy only if tests require. Green. `# [REQ-EXR-004]`.</step>

  <step id="7" status="complete">Write failing request/system specs for `GET /phase` nested or sibling resources for **routine** phase assignments (reuse patterns from `PhaseAssignmentsController`); Turbo partials consistent with existing phase UI. Green. `# [REQ-EXR-002]`.</step>

  <step id="8" status="pending">Write failing specs for Mi Día: `fitness_exercise` resolution; inline block only when habit due; global shortcut always; inactive habit disabled block; day preview + link to full-week routine view; Turbo links. Update `MyDayController` + views + I18n. Green. `# [REQ-EXR-003]`.</step>

  <step id="9" status="pending">Add home / primary nav links to routines list and/or phase plan per SPEC Q15; request spec. Green. `# [REQ-EXR-003]`.</step>

  <step id="10" status="pending">Update `docs/core/SCHEMA_REFERENCE.md` and `docs/core/DATA_FLOW_MAP.md` for new tables and flows (including delete cascade path and dual PlanEnded). Run full suite; fix regressions.</step>
</implementation_plan>
