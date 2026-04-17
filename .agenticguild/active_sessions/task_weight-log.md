% Task: weight-log
% Scope: ROADMAP Phase 6 — items **#23**, **#24** (`docs/ROADMAP.md`)
% Requirements: **REQ-WGT-001** (modelo), **REQ-WGT-002** (flujo de registro), **REQ-WGT-003** (historial) — `docs/core/SPEC.md`
% Status: Discovery **complete** — `<implementation_plan>` **locked** for **start-task**

---

## Goal (roadmap + SPEC)

1. **#23 / REQ-WGT-002** — UX para registrar entradas en el tiempo: **peso (kg)**, snapshot de **altura (cm)**, **BMI** derivado, alineado con el roadmap: **fecha + hora** del pesaje.
2. **#24 / REQ-WGT-003** — Vista de **historial** peso + BMI mostrando **progresión** en el tiempo.
3. **REQ-WGT-001** — Ya cubierto en código: tabla `weight_logs`, modelo, tests de modelo/servicio; Phase 6 completa la **superficie UX** y el historial.

**Dependencia explícita:** Phase 1 (perfil, peso actual, BMI en `User`) — satisfecha.

---

## Inventario del código actual (no inventar de cero)

| Pieza | Estado |
|--------|--------|
| `weight_logs` | `user_id`, `weight_kg` (decimal), `height_cm` (int), `bmi` (decimal), `created_at` / `updated_at`; índice `(user_id, created_at)`. **Pendiente migración:** `logged_at` (ver decisiones cerradas). |
| `WeightLog` | `belongs_to :user`; validaciones presencia y rango 20–500 kg; `attr_readonly :weight_kg, :height_cm`; BMI en `before_validation` (redondeo 2 decimales). |
| `LogWeightService` | Recibe `user`, `weight_kg`; usa **WeightKg**, **HeightCm** (perfil), **BmiValue.compute**; en transacción crea log y actualiza `user.current_weight_kg` y `user.current_bmi`. |
| Rutas / controladores / vistas | **No** hay flujo HTTP documentado aún para peso — Phase 6 lo añade. |

**Serie temporal:** tras migración, el instante lógico del pesaje será **`logged_at`** (UTC en BD; entrada en UI en TZ del usuario). `created_at` sigue siendo auditoría de guardado.

---

## Alineación (`docs/core/SYSTEM_ARCHITECTURE.md`)

- **Server-rendered + Turbo**; controladores delgados; si crece la orquestación, extraer servicio bajo `app/services/` (ya existe `LogWeightService`; podría renombrarse/moverse a `WeightLogs::*` por convención del repo — decisión en implementación).
- **I18n** para toda cadena visible; **`# [REQ-WGT-…]`** en tests según reglas de trazabilidad.
- **Accesibilidad:** errores con `aria-invalid`, resumen con `role="alert"` donde aplique (`ApplicationHelper#aria_for_field`).
- Tras cambios de flujo: actualizar **`docs/core/DATA_FLOW_MAP.md`** y **`docs/core/SCHEMA_REFERENCE.md`** si el esquema cambia.

---

## Domain Model

**Confirmed:** 2026-04-17 — user approved; no changes to types before TDD execution.

### **WeightLog** (existente)

- **Responsabilidad:** Snapshot inmutable de un pesaje con altura y BMI coetáneos al registro.
- **Invariants:** Pertenece a un `User`; `weight_kg` en [20, 500]; `height_cm` y `bmi` presentes; **`logged_at`** obligatorio para ordenar historial/gráficos; **no** se editan `weight_kg` ni `height_cm` tras crear (corrección: **borrar** entrada errónea y/o nueva medición — ver decisiones).
- **Value objects (existentes):** `WeightKg` (20–500), `HeightCm` (50–300 en servicio), `BmiValue.compute` — alinear redondeo con callback del modelo en cualquier flujo nuevo.

### **User** (contexto)

- **Invariants:** `current_weight_kg` / `current_bmi` reflejan el **último** pesaje exitoso vía `LogWeightService` (comportamiento actual).
- **Implicación UX:** Tras registrar peso, perfil/Mi Día deben verse coherentes con esos campos si el usuario espera “último peso = lo que acabo de guardar”. Con **`logged_at`**, “último” en sentido de producto = entrada con **`logged_at` más reciente** (no necesariamente la fila creada más recientemente si hay backdating).

---

## Decisiones cerradas (2026-04-17 — confirmación usuario)

1. **`logged_at` — Sí.** Migración: columna `logged_at` (datetime, `null: false` tras backfill); filas existentes: `UPDATE weight_logs SET logged_at = created_at`; índice recomendado `(user_id, logged_at)` para listados. Orden e historial: **`ORDER BY logged_at`** (y desempate estable si hace falta, p. ej. `id`). Formulario: selector fecha/hora interpretado en **zona horaria del usuario** (`User#timezone`), persistencia en UTC.

2. **Varios pesajes el mismo día — Sí, permitido.** Sin unicidad por día local; el usuario puede registrar más de una entrada en la misma fecha civil.

3. **Corrección de errores — borrado en Phase 6.** Las filas **no se editan** in-place (`attr_readonly`). El usuario puede **eliminar** la entrada equivocada desde el historial: **confirmación** obligatoria (modal o pantalla dedicada), **solo sus propias filas**. Tras borrar: **recalcular** `User#current_weight_kg` y `User#current_bmi` a partir del `WeightLog` con **`logged_at` máximo** entre las que queden; si **no queda ningún** log, poner `current_weight_kg` y `current_bmi` en **`nil`** (columnas ya nullable en `users`). Sigue siendo válido **añadir** una nueva medición en lugar de borrar; ambas conviven en producto.

4. **Altura — No cambia en el flujo de peso.** Siempre **snapshot de `user.height_cm`** al guardar (sin campo de altura en el formulario de pesaje). Coherente con `LogWeightService` actual.

5. **`logged_at` no puede ser futuro — CERRADO.** No permitir que `logged_at` sea **mayor** que el instante actual en la **zona horaria del usuario** (validación en modelo o servicio con `Time.use_zone(user.timezone)` + comparación clara). Sin tolerancia explícita salvo un epsilon mínimo en implementación si hiciera falta por precisión de tipos.

6. **Paginación del historial — CERRADO.** **30** entradas por página desde la primera versión (REQ-WGT-003); enlaces o controles “anterior / siguiente” (o equivalente accesible).

---

## Edge cases y “rincones oscuros”

| Tema | Riesgo / comportamiento |
|------|-------------------------|
| **Zona horaria** | Construir `logged_at` desde inputs locales + `user.timezone`; mostrar listas en hora local; no mezclar “día” agrupado sin TZ. |
| **“Último peso” del usuario** | Tras **crear** log, `LogWeightService` actualiza `current_*`. Tras **borrar**, servicio o callback debe **re-sincronizar** desde `MAX(logged_at)` o `nil` si no hay filas. |
| **Borrar la única fila** | `current_weight_kg` / `current_bmi` → `nil`; UI y perfil deben tolerarlo (REQ-PROF-002 habla de almacenar valores — revisar copy si quedan vacíos). |
| **Doble envío / Turbo** | Doble POST crea dos filas; idempotencia no existe hoy — mitigar con deshabilitar botón o deduplicación corta ventana (producto). |
| **Transacción** | `LogWeightService` ya revierte el log si falla `user.update!` — mantener cualquier extensión dentro de la misma transacción. |
| **Consistencia BMI** | `BmiValue` (servicio) vs `WeightLog#compute_bmi` (Float) — mismos límites numéricos en la práctica; evitar divergencias si se añaden campos calculados. |
| **Usuario sin altura válida** | `HeightCm` falla si perfil inválido — el flujo debe bloquear con mensaje claro (“completa altura en perfil”). |
| **Phase 7** | **REQ-RPT-003** — serie temporal por **`logged_at`**. |
| **Orden del historial** | **`logged_at DESC`, `id DESC`** (desempate estable); **30** por página. |
| **Alta con `logged_at` en el pasado (retroactivo)** | Tras crear una fila antigua, **`User#current_*` no debe copiar ciegamente la fila nueva**: deben reflejar la entrada con **`logged_at` máximo** (y `id` si empate). El `LogWeightService` actual asigna desde la fila creada — hay que **reconciliar** tras cada alta (misma regla que tras borrado). |
| **Cambio de TZ del usuario** | Filas guardadas en UTC son correctas; solo cambia la **presentación**. Validación “no futuro” debe usar TZ **actual** del usuario al guardar. |
| **Horario de verano (DST)** | Al componer local → UTC, usar APIs que respeten TZ IANA; probar mentalmente transiciones si hay inputs de fecha/hora locales. |

---

## Errores comunes en implementación

1. **Ordenar o graficar por `created_at`** tras introducir **`logged_at`** — el eje temporal del producto es `logged_at`.
2. **Olvidar actualizar `User` tras crear o borrar** — el borrado debe disparar el mismo tipo de **reconciliación** de `current_*` que el alta.
3. **Saltarse I18n** en flashes, etiquetas de gráfico/tablas y mensajes de validación.
4. **Tests sin `# [REQ-WGT-…]`** — incumbe a la política de trazabilidad del repo.
5. **Historial N+1** — para REQ-WGT-003, cargar con `current_user.weight_logs.order(...)` de forma eficiente; paginar si crece.
6. **Tras crear un log retroactivo, pisar `current_*` con esa fila** — incorrecto si existe otra fila con `logged_at` más reciente.

---

## Decision log

- **logged_at:** añadir columna + backfill + índice; UI en TZ del usuario.
- **Múltiples pesajes / día:** permitidos.
- **Corrección:** sin edición in-place; **borrado** de entrada equivocada **incluido en Phase 6** (confirmación + resync `User` o `nil`).
- **Altura:** solo perfil; sin campo en formulario de peso.
- **Futuro:** no `logged_at` posterior a “ahora” (TZ usuario).
- **Paginación:** 30 por página en historial.

---

## Readiness

Decisiones de producto cerradas. Caso extremo **retroactivo vs `current_*`** documentado (reconciliación por `MAX(logged_at)`). Plan de implementación siguiente listo para **start-task**.

<implementation_plan>
  <classification>Feature</classification>
  <tdd_mandate>Every behavior-bearing change is driven by a failing spec first (model, service, or request/system as appropriate), then implemented, then refactored. Tag examples with `# [REQ-WGT-…]` per traceability rules.</tdd_mandate>

  <step id="1" status="complete">Write failing **model** specs for `WeightLog`: `logged_at` required; validation that `logged_at` is not strictly after “now” in the user’s timezone; default scope or class method for ordering `logged_at DESC, id DESC`. Add **migration**: `logged_at` column, backfill `logged_at = created_at`, `null: false`, replace/add index `(user_id, logged_at)` suitable for listing; keep `created_at` for audit. Make specs green. `# [REQ-WGT-001]`</step>

  <step id="2" status="complete">Write failing **service** specs for **reconciling** `User#current_weight_kg` and `User#current_bmi` from the `weight_logs` row with **maximum `logged_at`** (tie-break `id`), or `nil` if none. Refactor **`LogWeightService`** to accept `logged_at` (and `weight_kg`), persist it on the new row, then call reconciler so a **retroactive** entry does not overwrite “current” when a newer `logged_at` exists. Extend/adjust existing `LogWeightService` specs. `# [REQ-WGT-002]`</step>

  <step id="3" status="pending">Write failing specs for **destroy**: authenticated user deletes own `WeightLog` only; confirmation flow as per app patterns; after destroy, run same **reconciler** for `User` stats. Implement `destroy` action + thin orchestration (service object under `app/services/` if non-trivial). Transaction safety. `# [REQ-WGT-002]` `# [REQ-WGT-003]`</step>

  <step id="4" status="pending">Write failing **request** (and optionally **system**) specs for **REQ-WGT-002**: new/create weight entry form (weight + datetime in user TZ; no height field); flash/validation errors with accessible patterns; Turbo-appropriate behavior consistent with the app. `# [REQ-WGT-002]`</step>

  <step id="5" status="pending">Write failing **request** specs for **REQ-WGT-003**: **index** lists logs ordered by `logged_at` descending with **30** per page and pagination controls; columns include weight, height snapshot, BMI, and **local** display of `logged_at`; **delete** control with confirmation. Implement controller, routes, ERB, I18n (`es`/`en`). `# [REQ-WGT-003]`</step>

  <step id="6" status="pending">Add **navigation** entry point(s) consistent with existing layout (e.g. profile or main nav — mirror patterns from menus/Mi Día shortcuts); request or system spec asserting link presence. `# [REQ-WGT-002]`</step>

  <step id="7" status="pending">Update **`docs/core/SCHEMA_REFERENCE.md`** and **`docs/core/DATA_FLOW_MAP.md`** for `logged_at` and flows (create, list, delete, reconcile). Align **`docs/core/SPEC.md`** acceptance language for REQ-WGT-002/003 if needed. Run full test suite; fix regressions.</step>
</implementation_plan>
