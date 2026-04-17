% Task: phase-3-mi-dia
% Goal: Implement “Mi Día” (REQ-DAY-001–004): today’s active habits in user TZ, mark done/failed, retroactive edits, per-habit streaks. Depends on Phase 2 habits core.

---

## Context from codebase (2026-04-16)

- **No** `habit_completions` (or equivalent) table yet; tracking is net-new.
- `Habits::NextOccurrence` implements only `daily` and `monthly`; `weekdays`, `every_x_days` raise or are stubbed. Roadmap **#10** shipped: `weekly` fue unificado en `weekdays`; **“due on date?”** para Mi Día debe cubrir todos los tipos restantes antes de REQ-DAY-001.
- Phase 2 memory (`task_phase-2-habits-core.md`): timezone changes recompute weekdays with **current** user TZ; no per-completion historical TZ snapshot.

---

## Domain Model (draft — CbC)

| Entity / concept | Responsibility | Invariants (draft) |
|------------------|----------------|-------------------|
| **Calendar day (per user)** | Anchor for “today” and retro edits | Derived from `User#timezone` + civil date; server uses TZ-aware conversion, not `Date.current` alone for UX. |
| **Habit occurrence / due day** | A given `UserHabit` is “expected” on a date or not | Must match `frequency_type` + `frequency_params` + `activation_date`; inactive habits never due. Tipos: `daily`, `weekdays`, `every_x_days`, `monthly` (sin `weekly`; #10 hecho). |
| **Completion record** | Persist **hecho** / **fallado** por (user_habit, local_date); **pendiente** sin fila o sin estado positivo | Max una fila BD por par; pendiente ⇒ sin registro o se borra registro al “volver a pendiente”. **UI:** el hábito debido **sigue en lista desmarcado** (no se oculta la fila de pantalla al desmarcar). |
| **Streak (derived)** | Solo días debidos **cerrados** (medianoche local pasada) sin **hecho** cuentan como fallo | **Hoy** abierto: no rompe racha hasta que cierre el día civil. Cadena = debidos consecutivos **hechos**; debido cerrado y no hecho ⇒ rompe. Hábito **inactivo** fuera de UI/racha/edición. |

### Value objects / branded types (draft)

- `UserLocalDate` — civil date in user TZ (avoid raw `Date` without TZ context in services).
- `CompletionStatus` — enum-like, not free string.
- `HabitId` / `UserHabitId` — optional if IDs proliferate in queries.

---

## Decisions (user-confirmed)

### Lote 1 — 2026-04-16

| Tema | Decisión |
|------|-----------|
| REQ-DAY-004 / día debido sin marcar | Sin **hecho** ⇒ para racha es **fallo** (no cuenta como día cumplido). |
| REQ-DAY-003 / estados | Editar hecho ↔ fallado; **volver a pendiente** (p. ej. eliminar registro en BD). |
| REQ-DAY-003 / alcance temporal | Retro **ilimitado**; **no** fechas futuras. |
| Hábito inactivo | No existe para Mi Día / edición / racha. |
| Timezone | TZ **actual** del usuario. |

### Lote 2 — 2026-04-16 (seguimiento)

| Tema | Decisión |
|------|-----------|
| “Una vez por semana” | En UI se elige el día; en BD es **`weekdays` con un solo elemento** `[d]` (#10 implementado). |
| `daily` | **Todos los días** (7/7). Subconjunto de días ⇒ tipo **`weekdays`** en UI/BD. |
| UI lista / desmarcado | Lo no marcado **no quita la fila de la vista**: el hábito debido **sigue visible desmarcado** (fila de pantalla). |
| Racha e **“hoy”** | Solo después de **medianoche local** cerrada: durante “hoy”, un debido sin hecho **no rompe** la racha mostrada. |

### Coherencia “pendiente” / racha (pasado)

Si un día debido **ya cerró** y no hay **hecho**, para la racha es **fallo**. Volver a pendiente (sin registro BD) **no perdona** ese día: sigue siendo debido cerrado sin hecho.

### Lote 3 — 2026-04-16 (cierre algoritmos / datos)

| Tema | Decisión |
|------|-----------|
| `weekdays` + `activation_date` | Primer día debido = primer `wday` en el conjunto **en o después** de `activation_date` (fecha local). **Confirmado.** |
| `every_x_days` | **`activation_date` es el primer día debido**; luego cada N días civiles locales: `(date - activation_date) % interval == 0`. |
| `activation_date` — edición | **Se puede editar** solo mientras **no exista ningún** registro de cumplimiento (hecho/fallo) para ese hábito. Si **ya hay** marcas, **no** se puede cambiar: solo **desactivar** + crear **otro** hábito. **Excepción explícita:** si el usuario borra **todas** las filas de cumplimiento (todo vuelve a pendiente en BD), **vuelve** a poder editar `activation_date`. Validar en `update` contra `exists?` en tabla de completados. |
| `monthly` | El mes que contiene `activation_date` **cuenta** (primer mes debido incluido; clamp fin de mes ya en REQ-HAB-009). |
| Mi Día / histórico antes de activación | **No** mostrar el hábito en fechas **anteriores** a `activation_date`. |
| `failed` explícito vs sin fila | **Misma** semántica para racha (ambos = no hecho en día cerrado). |
| Reactivar hábito | La racha **continúa** con datos existentes (completados conservados). |
| Migración `weekly` → `weekdays` | Migración defensiva aplicada en #10 (REQ-HAB-005). |
| Completados + hábito inactivo | **Conservar** filas en BD; **ocultar** en Mi Día / no editar mientras inactivo (índice único `(user_habit_id, local_date)` sigue válido). |
| Rendimiento historial largo | **Roadmap backlog** nuevo: optimización / paginación / caché cuando retro + racha escale (no bloquea Phase 3 inicial). |

---

## Model note: `daily` vs `weekdays` (sin `weekly`)

- **Roadmap #10 (hecho):** `weekly` se unificó en `weekdays` en `docs/ROADMAP.md`; “una vez por semana” = `weekdays` con array de un elemento.
- **Daily vs subset:** Mantener **`daily` = 7/7** y **`weekdays` = uno o más días** (incl. un solo día). Sin unificar `daily`+`weekdays` en un solo tipo salvo decisión futura.

---

## Open questions (remaining)

*(Vacío tras Lote 3; detalles menores se resuelven al escribir SPEC/implementación.)*

---

## Edge cases & dark corners

- **DST** — Spring forward / fall back: civil dates still OK; watch tests around `ActiveSupport::TimeZone`.
- **Empty timezone** — Model validates presence; still guard in services if legacy data.
- **SQLite + concurrency** — Unique index on (user_habit_id, date) prevents duplicate completions; handle `RecordNotUnique` in controller/service.
- **Streak computation cost** — N habits × scanning history: consider indexed queries or cached `current_streak` / `longest_streak` columns updated on write (Phase 7 wants reports too). **Diferido:** ver ítem backlog en `docs/ROADMAP.md` (optimización historial largo).
- **Edición del conjunto `weekdays`** — Si el usuario cambia los días, rachas e histórico se recalculan con **reglas actuales** (TZ actual + params actuales).
- **Racha en vivo** — Tests deben fijar “hora actual” o fecha límite: misma fecha puede ser “hoy” o “ayer” según TZ y `Time.current`.
- **Migración `weekly` → `weekdays`** — Completada en #10; no deben quedar filas `weekly`; tests y seeds alineados.

---

## Common implementation mistakes to avoid

- Using `Date.current` / `Time.zone.today` without scoping to **user** timezone.
- Storing **UTC midnight** as the completion date without documenting semantics — prefer explicit `date` column (DATE type) as **user local calendar date**.
- Computing streaks in the view or helper without tests — logic belongs in model/service with REQ tags in specs.
- Tratar **hoy** como fallido en racha antes de medianoche local (contradice decisión).
- Mezclar **`daily` y `weekdays`** en código sin política clara (duplicación de ramas `due_on?`).
- Ignoring **idempotency** on Turbo double-submits — unique DB constraint + friendly error or upsert pattern.

---

## Explore closure

Discovery **cerrada** el 2026-04-16. Fuente de verdad de decisiones: tablas Lote 1–3 arriba + `docs/ROADMAP.md` (#10–#14 y backlog). Siguiente paso humano/agente: skill **start-task** contra el plan siguiente.

---

<implementation_plan>
  <classification>Feature</classification>
  <scope>Roadmap Phase 3 (#10–#14): #10 unify `weekly`→`weekdays` (done elsewhere); `Habits::DueOnDate` (or equivalent) for all frequency types; `habit_completions` persistence; Mi Día UI; mark/retro/streak per `docs/core/SYSTEM_ARCHITECTURE.md` (thin controllers, services under `app/services/habits/`, I18n, REQ traceability in specs).</scope>

  <step order="1" status="completed">
    <title>SPEC and registry alignment</title>
    <action>Update `docs/core/SPEC.md`: extend planned `REQ-DAY-001`–`004` with agreed semantics (TZ actual, inactive hidden, retro unlimited no future, streak closed-days-only, explicit failed == absent for streak); REQ-HAB-005 / `weekly` removal tracked in `task_unify-weekly-weekdays.md`; document `activation_date` edit rule (zero completion rows including after delete-all); `every_x_days` day-0 formula; first `weekdays`/`monthly` occurrence rules. Follow `.cursor/rules/spec-md-req-registry.mdc`.</action>
    <tdd_note>Not code-first; do not skip before writing failing tests for domain code in later steps.</tdd_note>
  </step>

  <step order="2" status="completed">
    <title>Roadmap #10 — Remove `weekly` type</title>
    <action>**Done** in session `task_unify-weekly-weekdays.md`: spec rejects `weekly`, data migration, model + SPEC. Remaining plan steps here skip #10.</action>
    <tdd_note>Start with failing tests that assert the new allowed set and migration behavior.</tdd_note>
  </step>

  <step order="3" status="completed">
    <title>`Habits::DueOnDate` (calendar rules)</title>
    <action>Write failing unit specs for `due_on?(user_habit, local_date)` covering `daily`, `weekdays` (multi and single element), `every_x_days` with `(date - activation_date) % interval == 0` and no dues before `activation_date`, `monthly` with clamp consistent with REQ-HAB-009, and first occurrence ≥ `activation_date` for weekdays. Use user timezone for civil dates. Implement service until green.</action>
    <tdd_note>Every branch introduced by a failing test before implementation.</tdd_note>
  </step>

  <step order="4">
    <title>Completions model and DB</title>
    <action>Write failing model specs: `HabitCompletion` (name per project convention) belongs to `user_habit`, `completed_on` as DATE (user-local calendar semantics documented), status enum or string constrained to done/failed; unique index `[user_habit_id, completed_on]`; cannot create/update for inactive habit. Migration. Implement until green. `# [REQ-DAY-002]` groundwork.</action>
    <tdd_note>Failing model tests before migration application in dev.</tdd_note>
  </step>

  <step order="5" status="completed">
    <title>`activation_date` conditional immutability</title>
    <action>Write failing specs: `UserHabit` allows `activation_date` change when habit has zero completions; forbids change when at least one completion row exists; re-allows after all completions destroyed. Align with Lote 3. `# [REQ-HAB-005]` or new REQ row if split.</action>
    <tdd_note>Failing model tests first.</tdd_note>
  </step>

  <step order="6" status="completed">
    <title>Mi Día view (REQ-DAY-001)</title>
    <action>Write failing request or system specs: authenticated user sees only **active** habits due today per `DueOnDate` and user timezone; habits inactive omitted; none shown before `activation_date` for selected day. Controller thin; service composes list. I18n strings. Implement until green. `# [REQ-DAY-001]`.</action>
    <tdd_note>Failing integration/request spec before controller implementation.</tdd_note>
  </step>

  <step order="7" status="completed">
    <title>Mark done / failed / clear to pending (REQ-DAY-002)</title>
    <action>Write failing specs (request/system + service): mark today and past dates; reject future; Turbo-safe uniqueness; transitions done ↔ failed ↔ delete row; inactive habit returns error or redirect. Implement until green. `# [REQ-DAY-002]`.</action>
    <tdd_note>Failing tests before actions.</tdd_note>
  </step>

  <step order="8" status="completed">
    <title>Retro editing (REQ-DAY-003)</title>
    <action>Extend failing specs: unlimited past dates within due rules; no future; UI row remains visible when unchecked (behavioral spec where appropriate). `# [REQ-DAY-003]`.</action>
    <tdd_note>Extend with failing examples before code changes.</tdd_note>
  </step>

  <step order="9" status="completed">
    <title>Streak calculation (REQ-DAY-004)</title>
    <action>Write failing unit specs for dedicated service: consecutive **closed** due days with **done** only; today open does not break streak; inactive habits excluded; same semantics for explicit failed and no row. Freeze time with `travel_to` / zone helpers. Implement until green. `# [REQ-DAY-004]`.</action>
    <tdd_note>Streak logic must not live in ERB; test-first service.</tdd_note>
  </step>

  <step order="10">
    <title>Extend `Habits::NextOccurrence` and housekeeping</title>
    <action>Align `NextOccurrence` (or deprecate in favor of DueOnDate) for types still used in UI previews; update `# [REQ-HAB-009]` coverage as needed. Run full `bundle exec rspec`; fix lints on touched files.</action>
    <tdd_note>Any new behavior covered by failing test first.</tdd_note>
  </step>

  <verification>
    <item>All new examples carry `# [REQ-…]` comments per `.cursor/rules/spec-req-traceability.mdc`.</item>
    <item>No user-facing strings without I18n.</item>
    <item>Controllers remain thin; domain in models/services.</item>
  </verification>
</implementation_plan>
