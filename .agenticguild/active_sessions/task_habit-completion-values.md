# Task: Valores de completado por hábito (Backlog ROADMAP)

**Estado:** descubrimiento / whiteboard (explore-task)  
**Origen:** `docs/ROADMAP.md` → **Backlog** — primera línea: *Habit completion values*; dependencia explícita: Phase 3 (hecho). Desbloquea *Multiple completions per day*.

**Contexto código / SPEC:** Hoy `HabitCompletion` es **una fila única** por `(user_habit_id, completed_on)` con `status` `done` | `failed` y sin cantidad (`docs/core/SPEC.md` glosario — *Habit completion*). Servicios: `Habits::RecordCompletion`, `Habits::ClearCompletion`; rachas e informes asumen este modelo.

<roadmap_item>docs/ROADMAP.md — Backlog: Habit completion values (e.g. glasses of water, minutes of exercise); depends on Phase 3 (done).</roadmap_item>
<classification>Feature</classification>

<implementation_plan>
<step id="1" status="complete">Write a failing test first, then update `docs/core/SPEC.md`: extend the *Habit completion* glossary and **REQ-DAY-002** / **REQ-DAY-004** (or add a focused REQ) so that (a) `UserHabit` carries an editable **daily target** and **metric kind** (including none/binary for legacy habits), (b) `HabitCompletion` may store **accumulated progress for that local day** on the single row, (c) **effective day done** for streaks and reports matches one rule: keep `status` **synchronized** with product rules (progress ≥ target ⇒ `done` unless user chose `failed`; explicit `failed` wins). Preconditions: no schema change yet. Postconditions: every new behavior is named with REQ-IDs traceable from tests.</step>
<step id="2" status="complete">Write a failing test first, then add the **schema migration** and **ActiveRecord** layer: new columns on `user_habits` (metric kind + daily target with sensible defaults/backfill for existing rows) and on `habit_completions` (nullable progress for non-metric habits). Preconditions: SPEC from step 1 merged. Postconditions: models validate ranges (positive integers, caps per product), uniqueness `(user_habit, completed_on)` unchanged, inactive-habit guard unchanged.</step>
<step id="3" status="pending">Write a failing test first, then evolve **`Habits::RecordCompletion`** (and related entry points) so callers can set **done/failed** and **progress deltas or totals** as agreed in the session; after save, **recompute and persist `status`** from target + explicit user failure. Preconditions: models from step 2. Postconditions: **`Habits::ClearCompletion`** still removes the row or resets to pending per existing semantics; **`UserHabit#touch`** still runs so **Done #28** cache keys invalidate.</step>
<step id="4" status="pending">Write a failing test first, then align **`Habits::Streak`** / **`Habits::MiDayStreakPrefetch`** with the SPEC rule (minimal diff if `status` stays the single source of truth; if not, extend select + logic and keep one bounded query). Preconditions: service behavior from step 3. Postconditions: streak semantics match SPEC for metric and binary habits.</step>
<step id="5" status="pending">Write a failing test first, then update **reports / fulfillment** paths that classify a day as done so they use the **same** definition as Mi Día and streaks (no drift vs **REQ-RPT-001** / **REQ-DAY-004**). Preconditions: streak step green. Postconditions: integration or service specs cover at least one metric habit and one legacy binary habit.</step>
<step id="6" status="pending">Write a failing test first, then **Mi Día UI** (Hotwire): show progress vs target, actions to increment (e.g. +1 glass) and to mark explicit **failed**, consistent with **REQ-DAY-001** / **REQ-DAY-003**. Preconditions: HTTP/API for recording from step 3. Postconditions: accessible states (pending, in progress, done, failed) are visually distinct where product requires.</step>
<step id="7" status="pending">Write a failing test first, then **provisioning**: copy suggested **daily target** (and metric kind) from **`GlobalHabitTemplate`** / seeds into **`UserHabit`** on create, user-editable in habit settings UI. Preconditions: columns from step 2. Postconditions: default habits from registration reflect template suggestions per session decision 4.</step>
</implementation_plan>

## Domain Model

_Aprobado 2026-04-18. Ruby: clases value object con validación en el inicializador (o equivalente); sin primitivos sueltos en fronteras de dominio._

| VO | Responsabilidad | Reglas |
|----|-----------------|--------|
| `HabitMetricKind` | Clasifica cómo se mide el hábito en `UserHabit` | `none` (binario, sin cantidad), `count` (unidades discretas), `duration_min` (minutos enteros); conjunto cerrado. |
| `DailyTarget` | Objetivo diario editable en `UserHabit` cuando la métrica no es `none` | Entero ≥ 1; techo razonable fijado en SPEC / validación (p. ej. 99_999). Con `none`, valor canónico **1** (la UI no expone cantidad). |
| `ProgressAmount` | Acumulado del día en la única fila `HabitCompletion` | Entero ≥ 0; mismo techo que el target; representa el total del día civil local. |

**Precedencia (producto + persistencia):** `failed` explícito del usuario corta el día como no cumplido aunque haya progreso parcial; si no hay `failed` y `progress >= target`, el día cuenta como **done** para racha e informes; al persistir, `status` se **sincroniza** con esa regla.

---

## Prioridad respecto al resto del backlog

| Ítem backlog                         | Nota breve |
|--------------------------------------|------------|
| **Valores de completado** (este)     | **Prioridad sugerida #1** — base de dominio para métricas; sin esto, “múltiples completados” queda mal definido. |
| Múltiples completados / día          | Depende de este tema. |
| Unidades imperiales                  | Independiente; buen candidato si se busca entrega acotada sin tocar racha/informes. |
| Push / email por hábito              | Alcance grande (infra, permisos, idempotencia). |
| Columnas racha persistidas           | Solo si perf evidencia necesidad tras #28. |
| PostgreSQL                           | Condicionado a despliegue/ops. |

---

## Decisiones de producto (usuario, esta conversación)

1. **Cumplimiento del día:** se **deriva del objetivo** (p. ej. progreso ≥ objetivo ⇒ día contado como cumplido para racha / UX de “hecho”).
2. **Persistencia del progreso (elegido: A — datos):** **como mucho una fila** `HabitCompletion` por `(user_habit, día civil local)`. En esa fila: **acumulado del día** (p. ej. vasos). El **objetivo** se toma del **`UserHabit`** (decisión 4). La UI puede exponer muchos “+1”; en BD solo se actualiza el total agregado. *Opción B (tabla de eventos) queda fuera de alcance salvo nuevo backlog.*
3. **`failed` con objetivo:** **sí tiene sentido** — p. ej. el usuario declara que **no** va a cumplir el objetivo ese día (aunque lleve progreso parcial); la racha debe cortarse igual que hoy con `failed` o día debido sin fila.
4. **Objetivo diario (plantillas / defaults):** **Opción A (producto)** — cada plantilla / hábito por defecto define un **objetivo sugerido** que se **copia al `UserHabit`** al provisionar; el usuario puede **editarlo** en la ficha del hábito (misma línea que nombre, frecuencia, etc.). Los valores iniciales viven en seeds/plantilla (`GlobalHabitTemplate` o equivalente), no solo como constante oculta sin reflejo en BD del usuario.

---

## Domain model (borrador CbC)

- **Responsabilidad:** registrar **progreso del día** en `HabitCompletion`; el **objetivo vigente** vive en **`UserHabit`** (editable), originado desde plantilla al crear; reglas que derivan “día cumplido” vs **failed** explícito vs pendiente.
- **Invariantes:**
  - Día **cumplido para racha** ⇔ regla publicada (p. ej. `progress >= daily_target` y no `failed` explícito — orden de precedencia a fijar en SPEC).
  - **`failed`:** puede coexistir con progreso por debajo del objetivo; no cuenta como cumplido.
  - Rachas (`REQ-DAY-004`) e **Informes** deben usar la **misma** noción de “done efectivo”.
- **Value objects / tipos (propuesta):** `HabitMetricKind` (none | count | duration_min | …); `DailyTarget`, `ProgressAmount` (validación positiva / techo razonable).

---

## Riesgos / rincones oscuros

1. **Unicidad en BD:** con la opción **A**, el índice único `(user_habit_id, completed_on)` **sigue siendo válido**; el riesgo era solo si se hubiera elegido B (N filas/día).
2. **Streak prefetch + caché** (`MiDayStreakPrefetch`, `UserHabit#touch`): ver sección **Impacto Done #28** abajo.
3. **Retroactividad (`REQ-DAY-003`)** y **fechas futuras:** mismas guardas que hoy; rangos numéricos absurdos (99999 vasos) son validación de producto.
4. **Hábitos vinculados a rutinas/menús:** poco acoplados hoy; un “Ejercicio” con minutos no debe romper `REQ-EXR-003` ni shortcuts.

---

## Errores comunes a evitar en implementación (cuando pase a start-task)

- Cambiar el glosario SPEC / reglas de racha sin **tests** que cubran bordes (día cerrado sin fila = fallo implícito, hoy).
- UI que muestre “hecho” sin dejar claro si es **umbral** o **intención** del usuario.
- Olvidar invalidación de caché o lecturas N+1 al agregar joins/columnas.

---

## Impacto **Done #28** (caché / prefetch)

- **Lo que no cambia:** el **mecanismo** de invalidación — `Rails.cache.fetch` en `Habits::MiDayStreakPrefetch`, clave con versiones de `UserHabit`, y **`touch` en `RecordCompletion` / `ClearCompletion`** siguen siendo el patrón correcto. Tus respuestas **no** obligan a sustituir caché ni a otro tipo de prefetch.
- **Lo que sí habrá que tocar en código** cuando el “hecho” deje de equivaler a `status == "done"` tal cual:
  - Hoy `MiDayStreakPrefetch` selecciona `id, user_habit_id, completed_on, status` y `Habits::Streak` solo mira `comp&.status == "done"`.
  - **Opción de diseño recomendada para minimizar superficie:** al persistir, mantener `status` **coherente** con la regla de objetivo (p. ej. al alcanzar umbral ⇒ `done`; `failed` explícito del usuario ⇒ `failed` aunque haya progreso). Así `Streak` y el prefetch pueden seguir casi iguales, con tests nuevos para bordes.
  - **Alternativa:** dejar `status` solo como intención y que `Streak` derive cumplimiento de columnas `progress` / `target` ⇒ entonces **sí** ampliar el `.select` del prefetch y la lógica de `Streak` (misma clave de caché, más columnas en la query).

## Siguiente paso (skill)

Dominio de producto **cerrado** para esta sesión. Insertar bloque `<implementation_plan>` (TDD) en este archivo y ejecutar skill **start-task**.
