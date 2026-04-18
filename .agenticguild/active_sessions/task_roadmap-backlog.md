# Task: Exploración — Backlog (`docs/ROADMAP.md`)

**Estado:** **cerrado para implementación** — entregable activo: **Backlog #6** (optimización Mi Día / rachas con historial largo). Ejecutar con skill `start-task`.

**Nota:** Las preguntas 2–6 del whiteboard (catálogo público, métricas, imperial, recordatorios) quedan **fuera de scope** de esta sesión.

**Fuente:** `docs/ROADMAP.md` → sección **Backlog** (2026-04-18).

---

## Ítems del backlog (referencia)

1. Rutinas de ejercicio en **catálogo público** compartible (paridad menús/recetas + moderación) — depende Phase 5; fuera de scope hasta promoción.
2. **Valores de completado** por hábito (ej. vasos de agua, minutos) — depende Phase 3.
3. **Múltiples completados** el mismo día por hábito — depende de (2).
4. **Unidades imperiales** (lbs) para peso y perfil.
5. **Recordatorios** push / email para hábitos.
6. **Mi Día / rachas:** optimizar consultas, paginación o caché con historial muy largo.
7. **Reportes de racha (REQ-RPT-002):** opción de **materializar** racha si el cálculo en vivo escala mal — perfilar en producción.

---

## Alineación con arquitectura (`docs/core/SYSTEM_ARCHITECTURE.md`)

- Stack fijado: Rails 8, Hotwire, SQLite, Solid Queue, servicios bajo `app/services/`, I18n, trazabilidad `REQ-*` en `SPEC.md`.
- Moderación admin ya descrita para **revocar** compartido público (`Admin::BaseController`, `MOONLOOP_ADMIN_EMAILS`) — extensible a nuevos tipos “catalogables” si se añade sharing de rutinas.
- Hábitos / Mi Día / rachas: lógica central en `Habits::*` (`DueOnDate`, `RecordCompletion`, `Streak`, etc.); cualquier valor numérico o N completions/day **debe** mantener reglas de `REQ-DAY-*` y reporting (`REQ-RPT-*`).

---

## Domain model (CbC) — borrador por tema

### A. Catálogo público de rutinas (paridad menús)

- **Entidad (propuesta):** plantilla o “routine publish” enlazada a `ExerciseRoutine` del autor; flags `public`, `revoked_at`, posible `slug`/`title` para listado.
- **Invariantes:** solo el dueño publica; moderación solo filas actualmente públicas; no exponer datos de usuario no deseados en JSON/HTML.
- **Value objects:** identificador de publicación (no reutilizar `id` interno en URLs si hay riesgo de enumeración — decidir).

### B. Valores de completado + múltiples completados / día

- **Entidad:** ampliar `HabitCompletion` (o tabla hija) con `quantity` o filas múltiples; o estados agregados por día.
- **Invariantes:** “done” del día debe ser coherente con racha e informes: definir si racha exige **umbral** (ej. ≥8 vasos) o solo “marcado hecho”; hoy `REQ-DAY-002` es binario + failed.
- **Branded types:** `CompletionQuantity` (entero positivo + unidad opcional por plantilla de hábito); `HabitMetricKind` (enum: none, count, duration, …).

### C. Unidades imperiales

- **Entidad:** `User` — preferencia `unit_system` o campos duales; `WeightLog` sigue canónico en kg en BD o dual storage (preferir un canónico + conversión en capa presentación — **decisión**).
- **Invariantes:** BMI coherente con altura/peso mostrados; no pérdida de precisión en conversiones.

### D. Recordatorios hábitos

- **Entidad:** preferencias de canal, plantillas de notificación, `habit_reminder_events` (idempotencia similar a `phase_reminder_events`).
- **Invariantes:** respetar TZ usuario; no spam (ventanas, deduplicación por día+hábito).

### E. Rendimiento Mi Día / rachas / informes

- **Sin nueva entidad obligatoria:** índices, límites de ventana de consulta, o columnas derivadas (`current_streak_cache`, `longest_streak_cache`) actualizadas en `RecordCompletion` / `ClearCompletion`.

## Domain Model

**Alcance:** entrega activa — optimización Mi Día / rachas (backlog #6).  
**Aprobado:** 2026-04-18.

- **Entidades existentes (sin nuevos value objects / branded types):** `User`, `UserHabit`, `HabitCompletion`; el conteo de racha sigue calculándose únicamente mediante `Habits::Streak` (`REQ-DAY-004`).
- **Servicio de aplicación:** un objeto bajo `app/services/habits/` (nombre acorde al repositorio; p. ej. orquestación tipo `MiDayStreakPrefetch`) centraliza precarga para la ventana de racha, lecturas acotadas y uso de caché.
- **Caché:** claves que incluyen identidad del hábito, fecha local consultada y versión del registro (`cache_key_with_version`); invalidación coherente tras escrituras exitosas en `Habits::RecordCompletion` y `Habits::ClearCompletion` (p. ej. `user_habit.touch`).
- **No incluido en esta entrega:** tipos de dominio nuevos para cantidades/métricas; materialización persistente de rachas en BD.

---

## Preguntas abiertas (producto / dominio)

1. **Prioridad:** ¿Qué ítem del backlog entra primero en “Pending” del roadmap? (El whiteboard cubre varios; el plan de implementación debe ser **uno** por sesión `start-task`.)
2. **Rutinas públicas:** ¿Paridad estricta con flujo menús/recetas (mismo UX de “publicar”, listado, imagen, report abuse) o MVP solo “compartir enlace” sin catálogo?
3. **Métricas de hábito:** ¿Los valores son **solo informativos** o **definen** cumplimiento (umbral para “done”)?
4. **Múltiples completados:** ¿Suma del día, o varios eventos hora a hora (series temporales)?
5. **Imperial:** ¿Solo visualización o también entrada en lbs con persistencia en la unidad elegida?
6. **Recordatorios:** ¿Misma infraestructura que fases (email + banner) o push requiere proveedor (FCM/Web Push) y política de permisos?

---

## Casos extremos y rincones oscuros

- **Racha + cantidad:** Si “done” pasa a ser umbral, los días históricos sin cantidad registrada pueden volverse **ambigüos**; hace falta migración conceptual o regla “legacy = cumplido si había fila done”.
- **Informes (REQ-RPT-001/002):** Cualquier cambio en el significado de “completado” rompe paridad con `Habits::Streak` y fulfillment; hay que actualizar SPEC y tests de contrato.
- **TZ / DST:** Recordatorios y “día local” deben reutilizar las mismas abstracciones que Mi Día (`REQ-DAY-001`).
- **Catálogo público:** PII en nombres de rutinas/ejercicios escritos por usuario; moderación y términos; rate limits en publicación.
- **Materialización de racha:** Riesgo de **deriva** si los jobs fallan o hay edición retroactiva; definir quién es fuente de verdad (recompute nightly vs transaccional).
- **SQLite en producción:** Carga de informes y agregaciones largas — índices en `(user_habit_id, completed_on)` y evitar N+1 en vistas con muchos hábitos.

---

## Errores comunes a evitar

- Añadir columnas a `habit_completions` sin actualizar `Habits::Streak`, `FulfillmentForPeriod`, y los criterios en `SPEC.md`.
- Tratar “múltiples filas” como “múltiples días” en la racha.
- Duplicar lógica de “due day” en controladores en lugar de servicios.
- Recordatorios no idempotentes (doble email/push el mismo día).
- Conversión lb/kg con floats sin redondeo explícito en UI (confusión del usuario).
- Exponer IDs internos o emails en vistas públicas de catálogo.

---

## Próximo paso (workflow explore-task)

Handoff: skill **`start-task`** usando este archivo como fuente de verdad.

---

<implementation_plan>
  <classification>Feature</classification>
  <reference>docs/ROADMAP.md — Backlog: Mi Día / rachas (consultas, paginación o caché); docs/core/SPEC.md REQ-DAY-004; docs/core/DATA_FLOW_MAP.md §1.1; docs/core/SYSTEM_ARCHITECTURE.md (servicios Habits::*, controladores delgados)</reference>
  <goal>Reducir coste de CPU/memoria y lecturas innecesarias al mostrar Mi Día cuando existen muchas filas en `habit_completions`, sin cambiar la semántica de racha (`Habits::Streak` / REQ-DAY-004) ni los valores mostrados.</goal>
  <non_goals>No materializar rachas en BD en esta entrega (queda backlog aparte). No cambiar reglas de cumplimiento binario. No optimizar Informes salvo refactor seguro compartido si emerge de extracción de código.</non_goals>
  <risks>Claves de caché e invalidación: cualquier escritura vía `Habits::RecordCompletion` / `Habits::ClearCompletion` debe invalidar resultados dependientes (p. ej. `touch` en `UserHabit` para versionar `cache_key_with_version`). Evitar `delete_matched` si el backend de caché no lo soporta de forma fiable.</risks>

  <steps>
    <step order="1">Escribir tests que fallen: especificar un servicio bajo `app/services/habits/` (nombre final acorde al repo, p. ej. `Habits::MiDayStreakPrefetch` + orquestación) que, dado `user`, hábitos debidos en un día local y `@local_date`, produzca el mismo mapa de `habit_id` a `streak_count` que la lógica actual en `MyDayController` para escenarios representativos (incl. racha larga y hábito inactivo excluido de la lista debida).</step>
    <step order="2">Escribir tests que fallen: contrato de lectura eficiente — p. ej. que la precarga de completados para la ventana de racha use una consulta acotada por rango de fechas y hábitos debidos, y preferiblemente cargue solo columnas necesarias (`pluck` / `select`) sin instanciar filas completas si el beneficio es claro; mantener el índice existente `[user_habit_id, completed_on]`.</step>
    <step order="3">Implementar el servicio y mover la lógica fuera de `MyDayController` (`load_day_payload` / métodos privados de streak) para cumplir controladores delgados; mantener `Habits::Streak.call` como única fuente del número de racha.</step>
    <step order="4">Escribir tests que fallen: capa de caché (p. ej. `Rails.cache.fetch`) para el mapa de rachas o por hábito, con clave que incluya identidad del hábito, fecha local consultada y versión del registro hábito (`cache_key_with_version` tras `touch`); en entorno test usar almacén de caché coherente con el resto del proyecto.</step>
    <step order="5">Implementar invalidación: tras persistencia exitosa en `Habits::RecordCompletion` y destrucción exitosa en `Habits::ClearCompletion`, actualizar el modelo para que las lecturas posteriores no sirvan datos obsoletos (p. ej. `user_habit.touch` u otra estrategia equivalente documentada en el PR).</step>
    <step order="6">Verde: ejecutar la batería RSpec relevante (`my_day`, servicios `Habits::Streak`, regresión manual rápida Mi Día). Actualizar `docs/core/DATA_FLOW_MAP.md` §1.1 si el flujo de lectura cambia de forma visible.</step>
    <step order="7">Opcional de producto/repo: promover el ítem en `docs/ROADMAP.md` de Backlog a Pending o marcar rama en curso según convención del equipo.</step>
  </steps>
</implementation_plan>
