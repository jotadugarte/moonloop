# Task: Catálogo público de rutinas de ejercicio

**Origen:** `docs/ROADMAP.md` — **Pending #30** (catálogo público de rutinas; **#31** = menús después).  
**SPEC:** Q8 en *Decisions log — REQ-EXR* — al promover desde backlog: patrón **Done #29** + adopción / copia / avisos.  
**Paridad menús:** Misma semántica de producto para menús públicos (**ROADMAP #31**, tras cerrar **#30** / esta sesión). Esta sesión detalla **rutinas**; menús replican el patrón en otro entregable.

## Objetivo en una frase

**Catálogo público** de rutinas: opt-in del autor, moderación admin, **autor visible** (solo identidad de usuario, sin PII tipo email en la vista pública). El **origen** en catálogo refleja la **última** versión guardada del autor. **Solo usuarios autenticados** pueden **adoptar** (crear copia propia). **Una copia por usuario por rutina origen** (no segunda adopción del mismo origen). Las copias **no** se actualizan solas: aviso, revisión, **aceptar actualización** que aplica **solo el contenido estructural** (líneas); el **nombre de la copia elegido al adoptar se preserva siempre** (también tras aceptar sync). Si el origen se borra o deja de ser público: **vínculo “origen ya no disponible”**, la copia **sigue en manos del adoptante**; `show` público del origen **404/redirect coherente**, sin 500.

## Contexto técnico (estado actual)

- **Recetas:** `Recipe#publicly_shareable`, catálogo “vivo”, moderación admin.
- **Menús:** `publicly_shareable` + moderación; falta índice público y flujo adopción (ROADMAP actualizado).
- **Rutinas:** sin `publicly_shareable`; sin adopción ni `source_*`.

## Decisiones acordadas (producto y reglas)

| Tema | Decisión |
|------|----------|
| Autor en público | Mostrar **solo usuario** (identidad según modelo; **no** email ni PII innecesaria en catálogo). |
| Quién adopta | **Solo** usuarios **logueados**. |
| Adopciones por origen | **No**: como mucho **una** copia por `(usuario adoptante, rutina origen)`. |
| Autor edita varias veces antes de que el adoptante actúe | Tratar **solo el último** estado del origen respecto a la copia (comparar contra último reconciliado / fingerprint aceptado). |
| Nombre de la copia | **Siempre** el elegido por el adoptante al adoptar; **no** sobrescribir con el nombre del origen al **aceptar actualización** (solo líneas / contenido). |
| Origen borrado o revoke admin / dejar de ser público | Marcar vínculo **origen ya no disponible**; copia **permanece** con el adoptante. |
| Menús (backlog) | **Misma** semántica: catálogo, adoptar, avisos, reconciliación explícita, nombre de copia preservado, una copia por origen. |
| Rutina pública que quedaría inválida (vacía) | **Bloqueo de guardado** (validación actual); **no** auto-despublicar. |
| Colisión de nombre al adoptar | **Mismas reglas** que hoy para rutinas / normalización que **Menu** (unicidad por usuario); el flujo de adopción debe resolver igual que cualquier create (errores claros). |
| Aplicar actualización (concurrencia) | **Idempotente** respecto al estado del origen **en el momento de aplicar** (p. ej. fingerprint o `updated_at` + verificación; si el origen cambió de nuevo durante la acción, comportamiento definido en implementación: fallar con mensaje “hubo otro cambio, revisar de nuevo” o re-leer una vez — documentar en plan). |

## Arquitectura — duplicar vs adoptar (recomendación)

**Un solo motor interno** bajo `ExerciseRoutines::` (nombre tentativo p. ej. `CopyStructureFromRoutine`) que:

- Recibe **origen** (solo lectura) y **destino** (rutina nueva o existente según operación).
- Copia **solo líneas** en orden `(weekday, position)` con la semántica ya probada del **duplicate** actual.

**Duplicar** (feature actual): destino = rutina nueva del mismo usuario, **sin** `source_exercise_routine_id`, sin tracking de sync.

**Adoptar**: destino = rutina nueva del adoptante, **con** `source_exercise_routine_id`, columnas de “último origen visto / reconciliado”, y UI de avisos.

Así se evita divergencia de bugs entre dos copiadores paralelos.

## Domain model (CbC)

### ExerciseRoutine (extendido)

- **Responsabilidad:** Plan semanal del usuario; no vacío global (REQ-EXR-001).
- **`publicly_shareable`:** solo el dueño del origen; catálogo filtra `true`.
- **`source_exercise_routine_id`:** nullable; si presente, esta fila es **copia**; `user_id` es el adoptante; FK al origen mientras exista; si origen desaparece, FK nula o flag `source_unavailable` (decisión de esquema en plan).
- **Invariantes:** Un adoptante no puede tener dos filas con el mismo `source_exercise_routine_id` activo (índice único parcial o validación).
- **`PublicAuthorDisplay`:** proyección segura para vistas públicas (usuario, no email).

### Sincronización adoptante ↔ origen

- Detectar drift: preferir **fingerprint de contenido** de líneas + `updated_at` del origen como respaldo.
- **Aceptar:** reemplazar **solo** líneas de la copia desde snapshot válido del origen; **no** tocar nombre de copia ni `user_id`; `ExerciseRoutineAssignment` de la copia sigue apuntando al **mismo** `exercise_routine_id`.

### Catálogo público

- `index` / `show` sin scope por `Current.user` para **lectura** del origen; autorización estricta en mutaciones.

## Riesgos residual

- **Menú:** estructura distinta (entries/slots vs lines); el “mismo motor” será análogo por dominio (`Menus::CopyStructureFromMenu`), no reutilizar clase de rutinas literalmente.

## Pendiente menor (implementación / SPEC)

- **REQ-IDs:** `REQ-EXR-006` (y equivalente menú) + entradas en glosario cuando se ejecute.
- **Notificaciones:** asumir **in-app** como MVP salvo decisión explícita de email.

---

## Handoff

Spec de producto para **rutinas** cerrado. **Formalizado en roadmap (2026-04-18):** entregar **#30** (esta sesión) primero; **#31** (menús públicos, misma semántica) después. Menús: nueva sesión `start-task` tras cerrar catálogo de rutinas; servicios `Menus::*` análogos a `ExerciseRoutines::*`.

<implementation_plan>
  <classification>Feature</classification>
  <summary>Catálogo público de rutinas con opt-in, moderación admin, autor (solo identidad de usuario), adopción solo para sesión iniciada, una copia por origen y usuario, aviso y aplicación explícita de cambios de contenido desde el origen sin auto-sync ni cambio de nombre de la copia; origen indisponible con copia retenida; validación bloquea guardado si el origen quedaría inválido.</summary>
  <tdd_mandate>All behavior below is implemented test-first: request specs and/or model/service specs fail before implementation, then pass.</tdd_mandate>
  <steps>
    <step order="1" status="complete">Write failing RSpec examples for public catalog: `GET` index lists only `publicly_shareable` routines; `GET` show for public id; `404` when not public or revoked pattern; no leak of private routines; author display uses safe user identity only (no email in response body for catalog).</step>
    <step order="2">Write failing specs for adoption: authenticated user can adopt from public origin once; second adopt same origin returns conflict/validation error; unauthenticated cannot adopt; adopted routine has correct `user_id`, preserved chosen name, copied lines, `source_exercise_routine_id` set; unique name rules match existing Menu/routine normalization (failing case duplicate name).</step>
    <step order="3">Write failing specs for sync: when origin content changes, copy shows pending state; accepting update replaces lines only, preserves copy name and assignments on same routine id; idempotence / stale origin version rejected or re-fetched per agreed message; when origin deleted or no longer public, copy shows source unavailable, no 500 on old public URL.</step>
    <step order="4">Write failing spec for admin moderation: revoke sets `publicly_shareable` false on public routine only; scoped like recipes.</step>
    <step order="5">Add migration(s): `exercise_routines.publicly_shareable` (default false), self-referential `source_exercise_routine_id` (nullable), columns for last reconciled origin fingerprint/timestamp as designed; unique index ensuring at most one adopted copy per (adopter user, source) while source link active.</step>
    <step order="6">Implement `ExerciseRoutines::` service(s): content fingerprint helper; parameterized structure copy used by both duplicate flow and adopt; adopt orchestration; apply update from origin with transaction and line replace; guardrails for unavailable source.</step>
    <step order="7">Wire controllers/routes: `PublicExerciseRoutinesController` (or aligned name) index/show; authenticated adopt + review/accept actions; permit `publicly_shareable` on owner form; `Admin::ExerciseRoutinesController` revoke mirroring recipes. Thin controllers per SYSTEM_ARCHITECTURE.</step>
    <step order="8">I18n (es default, en) all new strings; a11y for alerts/banners on pending update and source unavailable.</step>
    <step order="9">Update `docs/core/SPEC.md`: REQ-EXR-006 (or agreed id), glossary/decisions; `docs/core/SCHEMA_REFERENCE.md` if maintained; traceability comments in code per project rules.</step>
    <step order="10">Run full test suite; fix regressions; manual smoke public catalog + adopt + accept + revoke.</step>
  </steps>
  <out_of_scope>Public menu catalog task (same semantics, separate REQ); email notifications; Web Push.</out_of_scope>
</implementation_plan>
