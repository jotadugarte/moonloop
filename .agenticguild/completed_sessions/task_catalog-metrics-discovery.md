% Task: catalog-metrics-discovery — ROADMAP **#34** — discovery (explore-task)
% Active session — `start-task` should take over for implementation.
% Discovery: **CERRADO** 2026-04-19 — especificación y `<implementation_plan>` bloqueados para ejecución.

---

# Task: Métricas de popularidad y búsqueda / discovery en catálogos (#34)

**Origen:** `docs/ROADMAP.md` pendiente **#34** — métricas (uso total, usuarios activos), orden por popularidad, filtros discovery (objetivos, dificultad, tags, duración planes) **(REQ-CAT-001)**.  
**Depende de:** **Done #30**, **#31**, **Done #33** (catálogos públicos de rutinas, menús y programas ya existen).  
**SPEC:** **REQ-CAT-001** — *pendiente de registro formal* en `docs/core/SPEC.md` (este archivo define el alcance de trabajo hasta que se escriba el REQ).

## Objetivo en una frase

Enriquecer **`public_menus`**, **`public_exercise_routines`** y **`public_phase_programs`** con **métricas visibles**, **ordenación por popularidad** y **criterios de filtrado** alineados al roadmap, sin romper el modelo de **solo usuarios autenticados** ni la semántica de adopción/sync existente.

## Contexto técnico (estado actual)

- **Índices públicos:** `Menu` / `ExerciseRoutine` / `PhaseProgram` con `where(publicly_shareable: true).order(:name)` en `PublicMenusController`, `PublicExerciseRoutinesController`, `PublicPhaseProgramsController`.
- **Adopción:** `Menus::AdoptFromPublicCatalog`, `ExerciseRoutines::AdoptFromPublicCatalog`, `Programs::AdoptFromPublicCatalog` — restricción **una copia por adoptante y origen** (`source_*_id` + índices únicos parciales).
- **Esquema:** no hay columnas de popularidad, tags, objetivos ni dificultad en plantillas públicas; la **duración** de un programa es derivable de `phase_program_assignments` (`max(end_week)` o suma de segmentos), no expuesta hoy en el catálogo.

## Decisiones de producto / dominio (borrador)

| Tema | Decisión propuesta (reversible en sesión) |
|------|---------------------------------------------|
| **“Uso total”** | Contador **monotónico** `public_catalog_adoptions_count` (o nombre alineado con convención del repo) en cada fila **plantilla** (`menus`, `exercise_routines`, `phase_programs`) incrementado en **transacción exitosa** de los tres servicios de adopción. Refleja **adopciones completadas**, no page views. |
| **“Usuarios activos”** | Dado **una copia por usuario y origen**, el número de **adoptantes distintos** coincide con el número de copias con `source_*_id` apuntando a la plantilla; mantener columna derivada **`public_catalog_distinct_adopters_count`** actualizada en el mismo punto (incrementar solo si el adoptante **no** tenía ya copia de ese origen; la adopción ya falla con `:already_adopted`). |
| **Orden por popularidad** | Parámetro permitido `sort=popular` (y default conservador `sort=name` para no cambiar UX sin query string) o default `popular` si producto lo confirma — **dejar explícito en REQ**; tests de request fijan el contrato. |
| **Discovery (tags, objetivo, dificultad, duración)** | Introducir metadatos **opcionales** visibles solo en contexto de catálogo/autor: preferir **una tabla polimórfica** `catalog_listing_facets` (o namespace `Catalog::`) con `listable_type` / `listable_id`, índice único, campos acotados (`goal_phrase` string limitada, `difficulty_level` enum string acotado, `tag_list` normalizado, `duration_weeks_min` / `duration_weeks_max` nullable para menús/rutinas; para **programas** puede **rellenarse por servicio** desde assignments al publicar o al guardar). Evita triplicar columnas free-form en tres tablas masivas. |
| **Privacidad** | Los facets son **declarados por el autor** para descubrimiento; no exponer PII; mantener línea de **autor = código público** ya existente. |
| **Moderación** | Revocar `publicly_shareable` mantiene el ítem fuera del catálogo; contadores y facets pueden quedar en BD (huérfanos de listado) — documentar si se borran en revoke o se ignoran solo en scope. |

## Domain Model

**Estado:** aprobado para ejecución TDD — 2026-04-19 (confirmación de sesión).

### Agregado principal

- **`Catalog::ListingFacet`:** como máximo **una** fila opcional por plantilla listable (`Menu`, `ExerciseRoutine`, `PhaseProgram`); validación + índice único compuesto `(listable_type, listable_id)`.

### Value objects (Ruby)

- **`Catalog::DifficultyLevel`:** enum cerrado; instanciación solo con valores permitidos.
- **`Catalog::TagList`:** lista normalizada (p. ej. minúsculas / slug) con límites de cardinalidad y longitud por tag.
- **`Catalog::WeekRange`:** `min_weeks` y `max_weeks` enteros ≥ 1, invariante `min_weeks <= max_weeks`; uso en filtros por duración de plan.

### Contadores en plantilla (atributos persistidos, no VO obligatorios)

- **`public_catalog_adoptions_count`** y **`public_catalog_distinct_adopters_count`** (o nombres finales alineados en SPEC): enteros **≥ 0**, **NOT NULL**, default `0`; solo mutados en transacciones exitosas de los servicios de adopción desde catálogo público (no page views).

### Invariantes transversales

- Solo el **dueño** del `listable` crea/actualiza facets.
- Si `publicly_shareable` es `false`, el facet **no** participa en consultas de catálogo público aunque persista en BD.
- `goal_phrase` y campos de facet sujetos a **límites de longitud/cardinalidad** anti-abuso (detalle en REQ-CAT-001).

## Riesgos / complejidad

- **Condiciones de carrera:** dos adoptantes simultáneos — usar `lock` en la fila plantilla o `increment!` atómico; tests de integración mínimos o comentario en REQ.
- **N+1 en índices:** `includes` + select de contadores y facet; orden por popularidad requiere índice compuesto `(publicly_shareable, public_catalog_adoptions_count)` o similar en las tres tablas.
- **Filtros combinados:** consultas polimórficas + JOIN a facets — posible objeto consulta `Catalog::PublicIndexQuery` por tipo para mantener controladores delgados.
- **Alcance vs “exploración”:** el roadmap mezcla métricas duras y discovery blando; riesgo de **PR gigante** — el plan por pasos permite entregar primero métricas + sort y luego facets + filtros si hace falta dividir PRs (documentado en pasos).

## Preguntas abiertas (resolver con producto antes o durante `start-task`)

1. ¿El listado por defecto debe seguir siendo **alfabético** o pasar a **popularidad** como default?
2. ¿“Usuarios activos” debe significar **solo adoptantes** (propuesta arriba) o usuarios con la copia **referenciada en un plan de fase activo** (consulta más costosa)?
3. ¿Los facets los edita el autor en la misma pantalla de **edit** privado (`menus#edit`, etc.) o en un subformulario / pestaña “Catálogo público”?

---

<task_session>
  <metadata>
    <task_name>Métricas y discovery en catálogos (#34)</task_name>
    <type>Feature</type>
    <req_id>REQ-CAT-001 (registro + criterios en SPEC — plan paso 1)</req_id>
    <roadmap_item>#34 — Métricas de popularidad y búsqueda avanzada (Catálogos); Depends on: #30, #31, Done #33</roadmap_item>
  </metadata>

  <implementation_plan>
    <classification>Feature</classification>
    <roadmap_item>34</roadmap_item>
    <summary>Métricas de adopción y adoptantes distintos en plantillas públicas de menús, rutinas y programas; ordenación por popularidad en los tres índices públicos; metadatos de discovery opcionales (tabla polimórfica) con filtros de consulta e i18n; REQ-CAT-001 en SPEC y referencias en SCHEMA / DATA_FLOW_MAP según toque tablas o flujos.</summary>
    <tdd_mandate>Cada paso: escribir o ampliar un spec que falle por el comportamiento nuevo, luego implementación mínima hasta verde. Migraciones “puras” solo cuando un spec ya las exija explícitamente.</tdd_mandate>
    <steps>
      <step id="1" status="complete">**SPEC primero:** añadir **REQ-CAT-001** en `docs/core/SPEC.md` (registro, glosario si aplica, criterios: visibilidad de contadores, semántica de incremento en adopción, sort permitidos, reglas de facets y filtros, edge cases revoke). Añadir fila de dominio / tabla en `docs/core/SCHEMA_REFERENCE.md` para columnas nuevas y `catalog_listing_facets` (o nombre cerrado). **Test:** ninguno aún si solo docs; si el proyecto exige spec de “REQ presente”, un spec de humo documental opcional — preferible en su lugar un request spec rojo en paso 2 que cite `[REQ-CAT-001]`.</step>
      <step id="2" status="complete">**Migración contadores:** `public_catalog_adoptions_count` y `public_catalog_distinct_adopters_count` (nombres finales alineados con convención) en `menus`, `exercise_routines`, `phase_programs`, default 0, NOT NULL. **Test primero:** request o modelo que espere columnas presentes (o spec de servicio que lea 0 por defecto).</step>
      <step id="3" status="complete">**Incremento atómico en adopción:** en los tres `*::AdoptFromPublicCatalog`, tras validar que no es `already_adopted`, dentro de la misma transacción incrementar contadores en la **plantilla origen** (y no en la copia). **Test primero:** specs de servicio existentes o nuevos con `[REQ-CAT-001]` que fallen hasta cablear el incremento; cubrir “primer adoptante” vs intento duplicado sin doble incremento.</step>
      <step id="4" status="complete">**Ordenación:** permitir `sort=popular` y `sort=name` (o el contrato cerrado en SPEC) en los tres controladores públicos; sanitizar params; índices DB si los explain locales lo justifican. **Test primero:** request specs en `spec/requests/public_menus_catalog_spec.rb`, `public_exercise_routines_catalog_spec.rb`, `public_phase_programs_catalog_spec.rb` (y adopt si aplica) que creen dos plantillas con contadores distintos y afirmen orden.</step>
      <step id="5" status="complete">**UI índice:** mostrar en cada ítem del listado público las dos métricas (i18n `es`/`en`), accesible (no solo color). **Test primero:** aserciones de HTML en los mismos request specs.</step>
      <step id="6" status="complete">**Modelo `Catalog::ListingFacet` (o nombre cerrado):** migración polimórfica, validaciones, asociación opcional `has_one` desde `Menu` / `ExerciseRoutine` / `PhaseProgram`. **Test primero:** `spec/models/catalog/listing_facet_spec.rb` con `[REQ-CAT-001]` — unicidad por listable, límites de tags, enum dificultad.</step>
      <step id="7" status="complete">**Autoría UI:** formulario en edición del dueño (o partial compartido) para crear/actualizar facet solo cuando el usuario es dueño; no requerir facet para publicar. **Test primero:** request spec en flujo `menus`/`exercise_routines`/`phase_programs` según alcance acordado (puede acotarse a un tipo en el primer PR si se documenta en SPEC como MVP incremental).</step>
      <step id="8" status="complete">**Filtros en catálogos públicos:** query params (`q`, `difficulty`, `tags`, `min_weeks`, `max_weeks`) con comportamiento documentado (AND de tags, búsqueda parcial en `goal_phrase`, etc.). Objeto consulta o scopes en `Catalog::` para mantener controladores delgados. **Test primero:** request specs con fixtures de facets que incluyan/excluyan filas.</step>
      <step id="9" status="complete">**Programas — duración:** servicio que derive `duration_weeks_max` desde `phase_program_assignments` al guardar facet o plantilla (definir en SPEC si es automático vs manual). **Test primero:** spec de modelo/servicio con dos segmentos de semanas.</step>
      <step id="10" status="complete">**Documentación de flujo:** actualizar `docs/core/DATA_FLOW_MAP.md` (lectura catálogo + adopción → contadores) y `SYSTEM_ARCHITECTURE.md` línea de servicios si aplica. **Test:** no obligatorio; revisión humana.</step>
    </steps>
    <out_of_scope>Analytics de vistas (page hits), recomendaciones ML, búsqueda full-text en recetas/rutinas internas, catálogo sin autenticación, internacionalización de tags libres más allá de normalización técnica.</out_of_scope>
  </implementation_plan>
</task_session>
