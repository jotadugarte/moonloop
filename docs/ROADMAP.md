# Project Roadmap

Things done and things left to do. Update this when finishing branches; use `roadmap-manage` to add, prioritize, or catalog items.

**Format:** Use `[x]` for done, `[ ]` for pending. Add `(REQ-ID)` to link to SPEC. Add `— YYYY-MM-DD` for done date. Add `— Branch: name` for in-progress. Add `— Depends on: Item` for dependencies. Item numbers are **global stable ids** (they are not renumbered when regrouping by phase; e.g. **#29** may appear under Phase 4 after **#19**).

---

## Done
### Phase 1 — Foundation & Auth
1. [x] Rails + Hotwire + SQLite project setup (REQ-PLAT-001) — 2026-04-16
2. [x] User authentication (sign up, login, logout, sessions, verification & password flows) (REQ-AUTH-001–007) — 2026-04-16
3. [x] User profile: age, weight, height, timezone (metric system) (REQ-PROF-001) — 2026-04-16
4. [x] BMI auto-calculation from weight and height (REQ-PROF-002) — 2026-04-16
36. [x] **Imperial units (US customary)** — weight + height: `body_unit_system`, `BodyMetrics`, registration/profile, weight log entry/history, Informes chart, mailer helper contract (**REQ-PROF-003**, **REQ-WGT-004**, **REQ-RPT-003** criterion 7) — 2026-04-19

### Phase 2 — Habits Core
5. [x] Habit model with frequency types: daily, weekdays, every X days, monthly (`weekly` removed and migrated — Done #10) (REQ-HAB-005) — 2026-04-16 — Depends on: Phase 1
6. [x] Default habits seeded per user on registration: Alimentación (Desayuno, Almuerzo, Cena, Merienda), Salud Física (Ejercicio, Agua), Emocional (Mascota) (REQ-HAB-002, REQ-HAB-001) — 2026-04-16 — Depends on: #5
7. [x] User-managed categories: create, edit, delete (REQ-HAB-003) — 2026-04-16 — Depends on: Phase 1
8. [x] Habits displayed grouped by category (REQ-HAB-008) — 2026-04-16 — Depends on: #5, #7
9. [x] Activate / deactivate habits (including default ones; re-activatable at any time) (REQ-HAB-007) — 2026-04-16 — Depends on: #5

### Phase 3 — Mi Día (Daily Tracking)
10. [x] Unify `weekly` into `weekdays`: remove `weekly` as a `frequency_type`; “once per week on day D” uses `weekdays` with a one-element array; migrate existing `weekly` rows; align validations, seeds, and SPEC (REQ-HAB-005) — 2026-04-16 — Depends on: Phase 2
11. [x] "Mi Día" view: show today's active habits resolved by user timezone (REQ-DAY-001) — 2026-04-16 — Depends on: Phase 2, #10
12. [x] Mark habit as done or failed for the current day (REQ-DAY-002) — 2026-04-16 — Depends on: #11
13. [x] Retroactive editing: mark or edit habits for past days (REQ-DAY-003) — 2026-04-16 — Depends on: #12
14. [x] Streak calculation per habit (consecutive days completed without failure) (REQ-DAY-004) — 2026-04-16 — Depends on: #12
32. [x] Habit completion values: `habit_metric_kind` + `daily_target` on `UserHabit`, `day_progress` on `HabitCompletion`; `Habits::RecordCompletion` syncs `status` with target / explicit failed; Streak, prefetch, fulfillment, and longest streak use **`Habits::Streak.habit_day_done?`**; Mi Día **+1** / **meet target** / failed; `GlobalHabitTemplate` suggested defaults + provision/copy + **edit habit** (**REQ-DAY-005**) — 2026-04-19 — Depends on: Phase 3 #11–#14
35. [x] Per-habit reminder **delivery:** after idempotent `habit_reminder_events` insert, `Habits::ProcessHabitReminderForUserHabit` sends email and/or Web Push (`Habits::DeliverHabitReminderWebPush`, `web-push` + VAPID) per channel toggles (**REQ-HAB-013**) — 2026-04-19 — Depends on: **REQ-HAB-010**–**012**, sweep (**REQ-HAB-011**)

### Phase 4 — Menus & Recipes (Alimentación)
15. [x] Menu model: weekly plan with one meal entry per day-of-week per meal type (Desayuno, Almuerzo, etc.) (REQ-MENU-001) — 2026-04-17 — Depends on: Phase 2
16. [x] Recipe model: name, instructions, image upload; default image provided per meal type (REQ-MENU-002) — 2026-04-17 — Depends on: #15
17. [x] Phase system: user defines a start date for Phase 1 and assigns week ranges to menus (e.g. weeks 1–4 → Menu A, weeks 5–12 → Menu B) (REQ-MENU-003) — 2026-04-17 — Depends on: #15
18. [x] Phase alerts: warn user if start date is more than 3 days in the future; send reminder on the day a phase begins (REQ-MENU-004) — 2026-04-17 — Depends on: #17
19. [x] Phase extension: when the current plan ends, prompt user to repeat the last phase or add a new week (REQ-MENU-005) — 2026-04-17 — Depends on: #17
29. [x] Public recipe catalog: browsable `public_recipes` index; recipes may opt into `publicly_shareable`; admin may revoke public sharing (moderation). `Menu` supports `publicly_shareable` for catalog + admin revoke (**REQ-MENU-006**). (REQ-MENU-002; SPEC glossary — `Recipe`, `Menu`) — 2026-04-17 — Depends on: #16
31. [x] Menús: catálogo público `public_menus` + adopción/sync con **paridad semántica** a rutinas (**REQ-EXR-006** / **Done #30**): usuarios autenticados, una copia por origen, nombre de copia estable al sincronizar, recetas duplicadas al adoptante en slots con receta, aviso/origen no disponible, moderación admin (REQ-MENU-006) — 2026-04-18 — Depends on: **Done #30**, Phase 4 (#15–19, #29)
33. [x] **Programas de Fases Unificadas (Bundles)**: entidad `PhaseProgram` con segmentos menú+rutina por rango de semanas, aplicación atómica al plan (`Programs::ApplyBundleToUser`), catálogo público, adopción integral y sincronización con origen en paridad con menús/rutinas (REQ-PHS-001); entrada en `/phase` y mapa de datos actualizado — 2026-04-19 — Depends on: **Done** #30, #31, Phase 4 (#17)

### Phase 5 — Exercise Routines
20. [x] Exercise routine model: assign exercises per day-of-week (REQ-EXR-001) — 2026-04-17 — Depends on: Phase 2
21. [x] Phase assignment for routines using same week-range system as menus (REQ-EXR-002) — 2026-04-17 — Depends on: Phase 4 (#15–19, #29), #20
22. [x] Surface active routine in "Mi Día" linked to the Ejercicio habit; add Mi Día shortcut(s) to exercise routine / plan screens (Turbo-friendly entry points, consistent with menus/phases shortcuts) (REQ-EXR-003) — 2026-04-17 — Depends on: #20, Phase 3 #11, Phase 4 (#15–19)
30. [x] Exercise routines: catálogo público (opt-in, moderación admin, **mostrar autor**). La **plantilla pública** en el catálogo sigue la **última versión** guardada por el autor. Si otro usuario **adoptó / usa una copia** en su cuenta, **no** se actualiza sola: aviso de que la rutina de origen cambió, puede **revisar** y **aceptar actualizar** su copia (REQ-EXR-006) — 2026-04-18 — Depends on: Phase 5 (#20–22), Phase 4 **#29**

### Phase 6 — Weight Log
23. [x] Weight log: record entries over time (date+time, weight_kg, height_cm snapshot, bmi) (REQ-WGT-002; model REQ-WGT-001) — 2026-04-17 — Depends on: Phase 1
24. [x] Weight + BMI history view showing progression over time (REQ-WGT-003) — 2026-04-17 — Depends on: #23

### Phase 7 — Reporting
25. [x] Habit completion report: fulfillment percentage per habit with weekly and monthly breakdown (REQ-RPT-001) — 2026-04-17 — Depends on: Phase 3
26. [x] Streak report: current streak and all-time longest streak per habit (REQ-RPT-002) — 2026-04-17 — Depends on: Phase 3 #14
27. [x] Weight progress chart: visual trend of weight over time (REQ-RPT-003) — 2026-04-17 — Depends on: Phase 6
28. [x] Mi Día / rachas: prefetch de completados acotado (`Habits::MiDayStreakPrefetch`), caché (`Rails.cache`) e invalidación vía `UserHabit#touch` tras completar o borrar día (REQ-DAY-004) — 2026-04-18 — Depends on: Phase 3 #11–#14
37. [x] Reportes / escalado: columnas o contadores **persistidos** en BD para racha (p. ej. actual / máxima por hábito) si, a pesar de **Done #28** (prefetch + `Rails.cache` en Mi Día), el coste en **Informes** u otros lectores sigue siendo alto — Depends on: Phase 7 #26–#28; perfilar en producción — 2026-04-22
40. [x] **Bug: UI Registro - Mostrar/Ocultar inputs de altura**. Al seleccionar sistema métrico o imperial, mostrar solo los inputs de altura correspondientes (centímetros o pies/pulgadas) y ocultar los otros (REQ-PROF-003) — 2026-04-23
41. [x] **Bug: Selección de Zona Horaria**. Cambiar el string estático por un combobox con zonas horarias reales, preseleccionando la zona detectada del navegador cuando aplica (REQ-PROF-001) — 2026-04-23
42. [x] **Bug: Etiqueta Sistema Imperial**. Etiqueta imperial unificada vía i18n (p. ej. “Imperial (pies / pulgadas)”) — 2026-04-23
45. [x] **Bug: Registro — altura métrico vs imperial**. HTML inicial y re-render 422 alinean visibilidad cm vs ft/in con `body_unit_system`; request specs [REQ-PROF-003] — 2026-04-24 — Depends on: Done #40

### Phase 8 — Catalogs
34. [x] **Métricas de popularidad y búsqueda avanzada (Catálogos)**: Contadores de adopción y adoptantes distintos, orden por popularidad, facets y filtros discovery (`q`, dificultad, tags, semanas), duración de programas derivada de segmentos (REQ-CAT-001) — 2026-04-19 — Depends on: #30, #31, #33

### Phase 9 — Infrastructure
38. [x] Migrar capa de datos a **PostgreSQL** (adapter, `database.yml`, migraciones/schema, job queue / caché alineados con el entorno objetivo, plan de datos desde SQLite) — 2026-04-22 — Depends on: entorno de despliegue y operaciones; stack actual REQ-PLAT-001 (SQLite desarrollo)
39. [x] Crear vistas sencillas de pantallas para poder ver la app en la web — 2026-04-22 — Branch: views

## In Progress
*(No items currently in progress.)*

## Pending (by priority)
Orden revisado **2026-04-24**: primero **bugs y registro** (impacto inmediato en nuevos usuarios y contenido roto), luego **flujos de uso frecuente** (menús, informes), **pulido de medios y sesiones**, **datos para QA/demos**, y al final el **refactor de dominio** (mayor alcance y dependencia de SPEC).

51. [ ] **Bug: Detalle de receta sin imagen**. En `/recipes/:id`, la imagen subida no se muestra (icono de imagen no encontrada); corregir carga/visualización del adjunto.
43. [ ] **Registro: peso opcional**. En la pantalla de registro, solicitar **peso actual** como campo **opcional**; si se deja sin llenar, mostrar en la misma pantalla una indicación clara de que puede **añadirlo o actualizarlo más tarde en el perfil** (REQ-PROF-001, REQ-WGT-002).
48. [ ] **Menús: flujo y edición sin fricción**. Tras escribir el nombre de un menú y guardar en `/menus`, redirigir directamente a `/menus/:id/edit` para completar el detalle del menú. En `/menus/:id/edit`, **sin botón “Guardar” por cada comida/plato**: al cambiar el combobox se **persiste automáticamente** la elección. Mostrar la **foto** del ítem (plato/comida) elegido en el combobox de cada slot.
47. [ ] **Informes: copy y navegación por pestaña**. En `/informes`: eliminar la línea “Semana y mes mostrados según este día: …”; renombrar “Día de referencia” a **“Día”**; semana como rango legible (“20 de abril al 26 de abril de 2026”); mes como **“Abril 2026.”** (sin rango día–día); enlaces **Cumplimiento · Rachas · Peso** deben mostrar **solo** el contenido de cada sección al activarlos.
50. [ ] **Nueva receta: vista previa de imagen**. En `/recipes/new`, al adjuntar imagen de la receta, subirla y **mostrarla en la página** (feedback inmediato).
46. [ ] **Sesiones: textos comprensibles para usuarios no técnicos**. En `/sessions`, sustituir o complementar datos crudos (User-Agent, IP `::1`, timestamp UTC) por mensajes en lenguaje claro que indiquen **desde qué dispositivo** y **desde dónde** se conectó la sesión (sin asumir conocimiento de redes ni cabeceras HTTP).
44. [ ] **Datos para pruebas**: cargar o mantener seeds/fixtures con escenarios representativos para desarrollo, demos y QA (fases y rangos de semanas, menús, recetas, rutinas de ejercicio, programas de fases / bundles, hábitos de ejemplo, etc.) — alineado con convención del proyecto (`db:seed`, tasks o factories).
52. [ ] **Reestructuración de entidad: de “Receta” a “Plato”**. Evolucionar el modelo para que el concepto central sea **Plato** (idea culinaria, p. ej. “Huevos revueltos”): la **receta** pasa a ser **opcional** (instrucciones de preparación no obligatorias); atributo **`tiene_receta`** para UI (mostrar pasos o preparación simple); justificación: precisión semántica, menús más naturales, menos fricción en ítems simples. Impacto: refactor de tabla/asociaciones, formularios con bloque receta dinámico o colapsable, rutas/controladores y nomenclatura coherentes con “plato”. — Depends on: Phase 4 (#16, rutas recetas/menús); alinear SPEC/glosario cuando exista criterio formal.

## Backlog
*(No items currently in backlog.)*

