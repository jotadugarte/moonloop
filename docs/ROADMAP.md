# Project Roadmap

Things done and things left to do. Update this when finishing branches; use `roadmap-manage` to add, prioritize, or catalog items.

**Format:** Use `[x]` for done, `[ ]` for pending. Add `(REQ-ID)` to link to SPEC. Add `— YYYY-MM-DD` for done date. Add `— Branch: name` for in-progress. Add `— Depends on: Item` for dependencies.

---

## Done
### Phase 1 — Foundation & Auth
1. [x] Rails + Hotwire + SQLite project setup (REQ-PLAT-001) — 2026-04-16
2. [x] User authentication (sign up, login, logout, sessions, verification & password flows) (REQ-AUTH-001–007) — 2026-04-16
3. [x] User profile: age, weight, height, timezone (metric system) (REQ-PROF-001) — 2026-04-16
4. [x] BMI auto-calculation from weight and height (REQ-PROF-002) — 2026-04-16

### Phase 2 — Habits Core
5. [x] Habit model with frequency types: daily, specific weekdays, every X days, weekly, monthly (REQ-HAB-005) — 2026-04-16 — Depends on: Phase 1
6. [x] Default habits seeded per user on registration: Alimentación (Desayuno, Almuerzo, Cena, Merienda), Salud Física (Ejercicio, Agua), Emocional (Mascota) (REQ-HAB-002, REQ-HAB-001) — 2026-04-16 — Depends on: #5
7. [x] User-managed categories: create, edit, delete (REQ-HAB-003) — 2026-04-16 — Depends on: Phase 1
8. [x] Habits displayed grouped by category (REQ-HAB-008) — 2026-04-16 — Depends on: #5, #7
9. [x] Activate / deactivate habits (including default ones; re-activatable at any time) (REQ-HAB-007) — 2026-04-16 — Depends on: #5

## In Progress
*(No items currently in progress)*

## Pending (by priority)

### Phase 3 — Mi Día (Daily Tracking)
10. [ ] Unify `weekly` into `weekdays`: remove `weekly` as a `frequency_type`; “once per week on day D” uses `weekdays` with a one-element array; migrate existing `weekly` rows; align validations, seeds, and SPEC (REQ-HAB-005) — Depends on: Phase 2
11. [ ] "Mi Día" view: show today's active habits resolved by user timezone (REQ-DAY-001) — Depends on: Phase 2, #10
12. [ ] Mark habit as done or failed for the current day (REQ-DAY-002) — Depends on: #11
13. [ ] Retroactive editing: mark or edit habits for past days (REQ-DAY-003) — Depends on: #12
14. [ ] Streak calculation per habit (consecutive days completed without failure) (REQ-DAY-004) — Depends on: #12

### Phase 4 — Menus & Recipes (Alimentación)
15. [ ] Menu model: weekly plan with one meal entry per day-of-week per meal type (Desayuno, Almuerzo, etc.) (REQ-MENU-001) — Depends on: Phase 2
16. [ ] Recipe model: name, instructions, image upload; default image provided per meal type (REQ-MENU-002) — Depends on: #15
17. [ ] Phase system: user defines a start date for Phase 1 and assigns week ranges to menus (e.g. weeks 1–4 → Menu A, weeks 5–12 → Menu B) (REQ-MENU-003) — Depends on: #15
18. [ ] Phase alerts: warn user if start date is more than 3 days in the future; send reminder on the day a phase begins (REQ-MENU-004) — Depends on: #17
19. [ ] Phase extension: when the current plan ends, prompt user to repeat the last phase or add a new week (REQ-MENU-005) — Depends on: #17

### Phase 5 — Exercise Routines
20. [ ] Exercise routine model: assign exercises per day-of-week (REQ-EXR-001) — Depends on: Phase 2
21. [ ] Phase assignment for routines using same week-range system as menus (REQ-EXR-002) — Depends on: Phase 4 #17, #20
22. [ ] Surface active routine in "Mi Día" linked to the Ejercicio habit (REQ-EXR-003) — Depends on: #20, Phase 3 #11

### Phase 6 — Weight Log
23. [ ] Weight log: record entries over time (date+time, weight_kg, height_cm snapshot, bmi) (REQ-WGT-002; model REQ-WGT-001) — Depends on: Phase 1
24. [ ] Weight + BMI history view showing progression over time (REQ-WGT-003) — Depends on: #23

### Phase 7 — Reporting
25. [ ] Habit completion report: fulfillment percentage per habit with weekly and monthly breakdown (REQ-RPT-001) — Depends on: Phase 3
26. [ ] Streak report: current streak and all-time longest streak per habit (REQ-RPT-002) — Depends on: Phase 3 #14
27. [ ] Weight progress chart: visual trend of weight over time (REQ-RPT-003) — Depends on: Phase 6

## Backlog
- [ ] Habit completion values (e.g. glasses of water, minutes of exercise) — Depends on: Phase 3
- [ ] Multiple completions per day per habit — Depends on: Backlog: Completion values
- [ ] Imperial units support (lbs) for weight and profile
- [ ] Push / email reminders for habits
- [ ] Mi Día / rachas: optimizar consultas, paginación o caché ante historial muy largo (retro ilimitado + racha desde el inicio; evitar vistas lentas) — Depends on: Phase 3 #11–#14
- [ ] Reportes de racha (REQ-RPT-002): valorar **materializar** racha (columnas o contadores derivados, p. ej. racha actual / máxima por hábito, actualizados al guardar) si el cálculo en vivo sobre historial largo es lento — Depends on: Phase 7 #26
