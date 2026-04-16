# Project Roadmap

Things done and things left to do. Update this when finishing branches; use `roadmap-manage` to add, prioritize, or catalog items.

**Format:** Use `[x]` for done, `[ ]` for pending. Add `(REQ-ID)` to link to SPEC. Add `— YYYY-MM-DD` for done date. Add `— Branch: name` for in-progress. Add `— Depends on: Item` for dependencies.

---

## Done
*(No completed items yet)*

## In Progress
*(No items currently in progress)*

## Pending (by priority)

### Phase 1 — Foundation & Auth
1. [ ] Rails + Hotwire + SQLite project setup
2. [ ] User authentication (sign up, login, logout, sessions)
3. [ ] User profile: age, weight, height, timezone (metric system)
4. [ ] BMI auto-calculation from weight and height

### Phase 2 — Habits Core
5. [ ] Habit model with frequency types: daily, specific weekdays, every X days, weekly, monthly — Depends on: Phase 1
6. [ ] Default habits seeded per user on registration: Alimentación (Desayuno, Almuerzo, Cena, Merienda), Salud Física (Ejercicio, Agua), Emocional (Mascota) — Depends on: #5
7. [ ] User-managed categories: create, edit, delete — Depends on: Phase 1
8. [ ] Habits displayed grouped by category — Depends on: #5, #7
9. [ ] Activate / deactivate habits (including default ones; re-activatable at any time) — Depends on: #5

### Phase 3 — Mi Día (Daily Tracking)
10. [ ] "Mi Día" view: show today's active habits resolved by user timezone — Depends on: Phase 2
11. [ ] Mark habit as done or failed for the current day — Depends on: #10
12. [ ] Retroactive editing: mark or edit habits for past days — Depends on: #11
13. [ ] Streak calculation per habit (consecutive days completed without failure) — Depends on: #11

### Phase 4 — Menus & Recipes (Alimentación)
14. [ ] Menu model: weekly plan with one meal entry per day-of-week per meal type (Desayuno, Almuerzo, etc.) — Depends on: Phase 2
15. [ ] Recipe model: name, instructions, image upload; default image provided per meal type — Depends on: #14
16. [ ] Phase system: user defines a start date for Phase 1 and assigns week ranges to menus (e.g. weeks 1–4 → Menu A, weeks 5–12 → Menu B) — Depends on: #14
17. [ ] Phase alerts: warn user if start date is more than 3 days in the future; send reminder on the day a phase begins — Depends on: #16
18. [ ] Phase extension: when the current plan ends, prompt user to repeat the last phase or add a new week — Depends on: #16

### Phase 5 — Exercise Routines
19. [ ] Exercise routine model: assign exercises per day-of-week — Depends on: Phase 2
20. [ ] Phase assignment for routines using same week-range system as menus — Depends on: Phase 4 #16, #19
21. [ ] Surface active routine in "Mi Día" linked to the Ejercicio habit — Depends on: #19, Phase 3 #10

### Phase 6 — Weight Log
22. [ ] Weight log: record entries over time (date+time, weight_kg, height_cm snapshot, bmi) — Depends on: Phase 1
23. [ ] Weight + BMI history view showing progression over time — Depends on: #22

### Phase 7 — Reporting
24. [ ] Habit completion report: fulfillment percentage per habit with weekly and monthly breakdown — Depends on: Phase 3
25. [ ] Streak report: current streak and all-time longest streak per habit — Depends on: Phase 3 #13
26. [ ] Weight progress chart: visual trend of weight over time — Depends on: Phase 6

## Backlog
- [ ] Habit completion values (e.g. glasses of water, minutes of exercise) — Depends on: Phase 3
- [ ] Multiple completions per day per habit — Depends on: Backlog: Completion values
- [ ] Imperial units support (lbs) for weight and profile
- [ ] Push / email reminders for habits
