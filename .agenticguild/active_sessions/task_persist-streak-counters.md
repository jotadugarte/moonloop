# Task: Persistir métricas/contadores de racha en BD (streak counters)

## Contexto (ROADMAP)
- Backlog: “Reportes / escalado: columnas o contadores persistidos en BD para racha (p. ej. actual / máxima por hábito) si, a pesar de Done #28 (prefetch + Rails.cache en Mi Día), el coste en Informes u otros lectores sigue siendo alto”.
- Dependencias: Phase 7 (#26–#28). Gate: **perfilar en producción** / evidenciar coste.

## Problema a resolver
Hoy el sistema calcula rachas desde `habit_completions` + reglas de “due day” (y hay optimizaciones para “Mi Día” vía prefetch + `Rails.cache`). En **Informes** u otros lectores, el coste puede seguir siendo alto (query + CPU) si se recalcula con frecuencia o sobre series largas.

## Objetivo
Definir un enfoque para **persistir** (en BD) contadores de racha por `UserHabit` (mínimo: racha actual y racha máxima histórica) que:
- reduzca coste de lectura en Informes u otras pantallas,
- mantenga consistencia con la lógica actual de “día cumplido” (`Habits::Streak.habit_day_done?`) y reglas de vencimiento/due,
- sea actualizable de forma incremental cuando se crea/edita/elimina un `HabitCompletion` y cuando cambian reglas relevantes del hábito.

## No-objetivos (por ahora)
- Reescribir el modelo de “racha” completo ni cambiar reglas de negocio.
- Optimizar “Mi Día” (ya existe el mecanismo de prefetch + cache; esto es para Informes/lecturas).
- Introducir infraestructura externa (Redis, etc.) sin ADR.

## Estado actual (a confirmar en código)
Confirmado en código:
- **Definición “done”**: `Habits::Streak.habit_day_done?` requiere `completion.status == "done"`. Si `habit_metric_kind == "none"` cuenta como done; si es medible, requiere `completion.day_progress >= user_habit.daily_target`. (`app/services/habits/streak.rb`)
- **Current streak (Informes)**: `Habits::ReportCurrentStreak` delega 1:1 a `Habits::Streak.call(...)` con `as_of:`. (`app/services/habits/report_current_streak.rb`)
- **Longest streak (Informes)**: `Habits::LongestStreak` escanea desde `lower_bound` hasta `through_date` y avanza runs solo en **días due**; “hoy” se trata como día “abierto” (no rompe la racha si no está done). Para hábitos inactivos usa `schedule_only:` en `DueOnDate`. (`app/services/habits/longest_streak.rb`)
- **Informes orchestration**: `ReportsController#show` llama a `Reports::ShowPage` (read-only). `Reports::ShowPage` pre-carga completions para todos los hábitos en un rango **start_on..end_on** donde:
  - `start_on` = min(lower_bound de todos los hábitos, combined_from[week+month])
  - `end_on` = max(combined_to[week+month], local_date)
  Luego construye `streak_rows` calculando para cada hábito `current` y `longest` usando el índice pre-cargado. (`app/services/reports/show_page.rb`, `app/controllers/reports_controller.rb`)

## Opciones de diseño (candidatas)
### Opción A — Columnas denormalizadas en `user_habits`
- Añadir columnas: `current_streak_count`, `longest_streak_count` (y opcionalmente `current_streak_as_of_date` / `longest_streak_achieved_on`).
- Pro: lectura muy barata; fácil de indexar/seleccionar por `user_id`.
- Con: hay que definir triggers claros de recomputación incremental vs recomputación parcial.

### Opción B — Tabla auxiliar `user_habit_streak_stats`
- Una fila por `user_habit_id` con contadores + metadatos.
- Pro: separa concerns; permite backfill y locking específico.
- Con: complejidad extra; joins en lecturas (aunque indexable).

### Opción C — Materialized summary recalculable (job) + “stale-while-recompute”
- Mantener contadores persistidos pero recomputados por job (Solid Queue) cuando se detecta “dirty”.
- Pro: amortiza coste; evita lógica compleja en path de escritura.
- Con: eventual consistency; UX/expectativas deben quedar claras.

## Eventos que invalidan contadores (lista inicial)
- Crear/actualizar/eliminar `HabitCompletion` (especialmente cambios de `status` o valores).
- Cambios en el schedule / frequency del hábito (weekdays / every X days / monthly / etc.).
- Cambios que afectan “due day” o interpretación por zona horaria.
- Cambios de objetivo/metric-kind (si “done” depende de target vs estado explícito).

## Preguntas abiertas / datos necesarios
- ¿En qué pantallas concretas duele el coste? (Informes, listados, API, etc.)
- ¿Cuál es la definición exacta de “racha actual” para Informes? (p.ej. hasta hoy local; ¿incluye “fallos” como ruptura definitiva?)
- ¿Cómo se representa “failed” vs “not done” en `HabitCompletion` y cómo afecta racha?
- ¿La racha debe contemplar días “no due”? (probable: sí, se salta esos días según `Habits::DueOnDate`/`DueHabitsForDay`).
- ¿Qué volumen esperado (completions por user) y qué latencia objetivo?

## Estrategia de implementación (borrador, sin lock)
- Añadir persistencia (A o B) y mecanismo de backfill.
- Implementar actualizaciones incrementales en puntos de escritura (`RecordCompletion`/`ClearCompletion`) con recomputación acotada (ventana) o full-per-habit según coste.
- Añadir un job de “reconciliación” para casos edge (cambios de schedule/timezone).
- Medir performance en Informes antes/después con dataset representativo.

## Observaciones de rendimiento (a partir del código actual)
- Aunque `Reports::ShowPage` evita N+1 de completions (hace una query para todos los hábitos del usuario), **la ventana de carga** se expande hasta el `lower_bound` mínimo entre hábitos para poder calcular racha actual/longest con consistencia. Eso puede implicar cargar muchos `HabitCompletion` (memoria + tiempo) en usuarios con historial largo.
- `Habits::LongestStreak` es \(O(\text{días calendario})\) por hábito (filtrando por due days). Con muchos hábitos y/o historiales largos, esto puede dominar el tiempo de `/informes`.

## Decisión pendiente (recomendación preliminar)
- Priorizar **Opción A (columnas denormalizadas en `user_habits`)** si el objetivo es acelerar Informes sin joins, manteniendo el “single query prefetch” para otras métricas.
- Mantener un mecanismo de “recompute on demand/job” (Opción C) como red de seguridad para cambios de schedule/timezone (evitar lógica incremental demasiado frágil).

## Estado actual (confirmado) — puntos de escritura
- `Habits::RecordCompletion`:
  - Valida ownership, activo, no futuro, y **due_on?**.
  - Upsert por `(user_habit_id, completed_on)`.
  - Para hábitos medibles, **sincroniza** `status` con `day_progress >= daily_target` salvo `failed` explícito.
  - Hace `@user_habit.touch` al guardar (cache coherence, ya usado por Mi Día).
- `Habits::ClearCompletion`:
  - Valida ownership y activo.
  - `destroy!` de la fila y `habit.touch`.

## Estado actual (confirmado) — esquema relevante
- `habit_completions`:
  - Índice único: `(user_habit_id, completed_on)`; columnas: `status`, `day_progress`, `marked_failed_by_user`.
- `user_habits`:
  - No existen contadores persistidos de racha hoy.

## Implicación clave para “persistir contadores”
Como ya tenemos un **hook natural** en los caminos de escritura (Record/Clear + touch), podemos:
- mantener contadores en el mismo `user_habits` (denormalizado),
- invalidar/actualizar justo después de cada write,
- y seguir usando `updated_at` como parte de keys de cache (Mi Día) sin cambiar el contrato.

## Implicación clave — Informes permite fecha pasada
`GET /informes` acepta `fecha=YYYY-MM-DD` (pasada, no futura). En `Reports::ShowPage`:
- `local_date` puede ser **hoy** o un día **pasado** (válido),
- `current` usa `Habits::Streak(as_of: local_date)`,
- `longest` usa `Habits::LongestStreak(through_date: local_date)`.

Por lo tanto, **un contador persistido “hasta hoy” no es correcto** cuando el usuario consulta Informes para una fecha pasada (porque incluiría completions posteriores).

### Recomendación de producto/arquitectura para aprovechar persistencia sin romper exactitud
- Persistir contadores solo para el caso común **local_date == user_today** (vista “hoy”).
- Mantener el cálculo “en vivo” cuando `fecha` sea pasada (correctitud > perf) y opcionalmente optimizar ese caso más adelante (p. ej. caching por fecha, o summaries por día si se vuelve requisito).

## Cambios de hábito y su impacto en rachas (estado actual)
- `UserHabitsController#update` hoy permite editar: `name`, `habit_metric_kind`, `daily_target`, y campos de reminder.
  - Cambios en `habit_metric_kind` / `daily_target` alteran la noción de “done” para hábitos medibles, así que cualquier contador persistido debe marcarse **stale** y recomputarse.
- `activation_date` está bloqueada si hay completions (validación `activation_date_locked_if_completions_exist`), lo cual reduce casos complejos de “shift” del lower bound.
- `frequency_type` / `frequency_params` no parecen editables vía ese controller hoy; si se habilitan en el futuro, deben entrar a la lista de invalidaciones.

## Propuesta concreta (para cerrar spec)
### 1) Qué persistir
En `user_habits` (Opción A):
- `current_streak_today` (integer, >= 0): racha actual **como de hoy** (user-local today).
- `longest_streak_through_today` (integer, >= 0): longest streak **hasta hoy** (user-local today).
- `streak_counters_as_of` (date): qué “hoy” usó el cálculo (en la zona del usuario).
- `streak_counters_stale` (boolean): marca de “necesita recompute”.

Notas:
- No persistimos “racha a una fecha arbitraria” (porque `/informes?fecha=` pasado existe).
- `streak_counters_as_of` permite distinguir “no computado hoy” vs “computado ayer”.

### 2) Cuándo actualizar (write path)
En `Habits::RecordCompletion` y `Habits::ClearCompletion`, después de persistir cambios:
- Si `local_date == user_local_today`:
  - recalcular **current** y **longest** “through today” para ese `user_habit` (o al menos current) y guardar en `user_habits`.
- Si `local_date < user_local_today` (retroactivo):
  - marcar `streak_counters_stale = true` (porque puede afectar longest y/o current dependiendo del gap).

Justificación: mantener el path común rápido sin meter lógica incremental frágil para edits retroactivos.

### 3) Cuándo invalidar por cambios en el hábito
En updates de `UserHabit` que cambien `habit_metric_kind` o `daily_target`:
- marcar `streak_counters_stale = true` (y opcionalmente limpiar `streak_counters_as_of`).

Si en el futuro se habilitan cambios a `frequency_type`/`frequency_params`:
- también deben marcar stale (cambio de due-day rules).

### 4) Cómo leer en Informes sin romper exactitud
En `Reports::ShowPage#streak_rows`:
- Si `local_date == user_today` y `streak_counters_stale == false` y `streak_counters_as_of == user_today`:
  - usar los contadores persistidos.
- Si `local_date` es pasado, o stale, o as_of desfasado:
  - fallback al cálculo actual (`Habits::ReportCurrentStreak` / `Habits::LongestStreak`) usando completions indexado.

### 5) Reconciliación / backfill
Agregar un job (Solid Queue) “recompute streak counters”:
- Recalcula `current` y `longest` hasta hoy para un `user_habit` (usando `Habits::Streak` y `Habits::LongestStreak`).
- Se encola cuando se marca stale (retroactivo o cambios de target/metric), y/o en un sweep diario para “as_of != hoy”.

### 6) Métrica de éxito (antes/después)
- Tiempo total de `GET /informes` para usuarios con:
  - muchos hábitos (p.ej. 50–200),
  - historial largo (p.ej. 1–2 años),
  - mezcla de hábitos due/no-due.
- Aceptación: “hoy” debe mejorar claramente; “fecha pasada” mantiene correctitud, performance puede quedar igual por ahora.

<implementation_plan>
  <roadmap_item>Backlog — Reportes / escalado: columnas o contadores persistidos en BD para racha (p. ej. actual / máxima por hábito) si, a pesar de Done #28 (prefetch + Rails.cache en Mi Día), el coste en Informes u otros lectores sigue siendo alto.</roadmap_item>
  <classification>Feature</classification>
  <constraints>
    <constraint>Must preserve exactness for `/informes?fecha=` past dates (no “through today” counters for historical pages).</constraint>
    <constraint>Must reuse existing semantics for “done” (`Habits::Streak.habit_day_done?`) and due-day rules (`Habits::DueOnDate`).</constraint>
    <constraint>No changes to business rules; optimization only.</constraint>
  </constraints>
  <steps>
    <step>Write failing specs for the new persisted counters behavior: (a) `/informes` for today uses persisted counters when fresh and not stale, (b) `/informes?fecha=past` still computes live (ignores persisted counters), (c) retroactive completion marks stale, (d) editing `daily_target` or `habit_metric_kind` marks stale, (e) reconciliation recompute clears stale and sets `as_of` to today. (DONE)</step>
    <step>Add a migration adding columns to `user_habits`: `current_streak_today` (int, default 0, null false), `longest_streak_through_today` (int, default 0, null false), `streak_counters_as_of` (date, null), `streak_counters_stale` (bool, default true, null false). Add any necessary indexes if reads filter by stale/as_of. (DONE)</step>
    <step>Implement a service `Habits::RecomputeStreakCounters` that computes `current` and `longest` through user-local today using `Habits::Streak` and `Habits::LongestStreak`, writes the counters, sets `streak_counters_as_of=today`, and clears `streak_counters_stale=false`. Ensure it is idempotent. (DONE)</step>
    <step>Implement a job `Habits::RecomputeStreakCountersJob` (Solid Queue / ActiveJob) that calls the service for a given `user_habit_id` and safely no-ops if the record is missing. (DONE)</step>
    <step>Update `Habits::RecordCompletion` and `Habits::ClearCompletion` to: if `local_date == user_local_today`, recompute counters inline (or enqueue job) after the write; if `local_date < user_local_today`, set `streak_counters_stale=true` and enqueue recompute job. (DONE)</step>
    <step>Update `UserHabit` (or the controller/service that updates habit metrics) so changes to `daily_target` and/or `habit_metric_kind` mark `streak_counters_stale=true` and enqueue recompute job. (DONE)</step>
    <step>Update `Reports::ShowPage#streak_rows` so when `local_date == user_today` and counters are fresh (`stale=false` and `as_of==today`), it uses persisted values; otherwise it falls back to live calculation using the existing preloaded completion map. (DONE)</step>
    <step>Run the full test suite; iterate until green. Add any missing unit tests around the “freshness” predicate and job enqueuing to prevent regressions. (DONE)</step>
  </steps>
  <test_plan>
    <item>Unit: `Habits::RecomputeStreakCounters` computes same values as `Habits::Streak` + `Habits::LongestStreak` for today.</item>
    <item>Service: `Habits::RecordCompletion` today updates counters; retroactive marks stale and enqueues recompute.</item>
    <item>Service: `Habits::ClearCompletion` mirrors behavior (today vs past).</item>
    <item>Request: `/informes` today uses persisted counters when fresh; `/informes?fecha=past` ignores them.</item>
  </test_plan>
</implementation_plan>

