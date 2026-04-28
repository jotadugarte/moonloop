## Task

**Roadmap item:** #52 — Reestructuración de entidad: de «Receta» a «Plato»

**Classification:** Feature (refactor de dominio + superficie producto)

**REQ / docs:** Alinear `docs/core/SPEC.md`, glosario y `docs/core/DATA_FLOW_MAP.md` / `SCHEMA_REFERENCE.md` cuando exista criterio formal (**ROADMAP**). Hoy **REQ-MENU-001/002** y glosario hablan de **Recipe** como entidad central en slots.

## Alcance acordado (discovery)

1. **Solo #52** (sin arrastrar otros ítems salvo dependencias inevitables del propio cambio).
2. **Por fases** (entregables incrementales; ver sección Fases propuestas — borrador).
3. **Catálogo público** (`public_recipes`, adopción menús que duplica recetas, moderación admin) **dentro del mismo trabajo**, no aplazado.

## Domain Model (CbC — aprobado 2026-04-27)

*Tipos: ver tabla inferior.* Sin cambios respecto al borrador anterior; listo para tests e implementación.

| Entidad / VO | Responsabilidad | Invariantes (borrador) |
|--------------|-----------------|------------------------|
| **`Dish`** (modelo ActiveRecord; UI “Plato”) | Ítem culinario de usuario: nombre, tipo de comida, imagen opcional, visibilidad catálogo; **instrucciones de preparación opcionales** (columna actual `instructions`). | Pertenece a un `User`; `meal_type` válido (`Menus::MealType`); nombre presente; imagen sometida a `ImageUploads::SafetyLimits` como hoy. |
| **Receta (concepto de producto)** | Bloque de texto “cómo prepararlo”; vive en el mismo registro que el plato (`instructions`). Puede estar vacío. | **`tiene_receta` en UI = derivado (A):** hay receta/instrucciones si `instructions.to_s.strip.present?` — sin columna booleana. |
| **`MenuEntry`** | Slot semanal; referencia al `Dish` del dueño del menú y/o `freeform_text`. | Misma regla de contenido que hoy: plato **o** texto libre según perfil; unicidad `(menu, weekday, meal_type)`; plato debe ser del dueño del menú. |
| **Catálogo / adopción** | Duplicar platos del autor al adoptante (evolución de `DuplicateRecipeForAdopter` → equivalente `Dish`, `dish_id` en mapas). | Un adoptante por origen; copias con metadata de sync; fingerprints deben incluir identidad del **contenido** del plato (nombre, instrucciones, imagen, flags). |

### Value objects / tipos (reuso)

- **`Menus::MealType`**, **`Menus::Weekday`**: sin cambio de contrato salvo renombres de copy.
- **`ImageVariants::*` / helpers de imagen:** mismas reglas (`docs/core/IMAGES.md`).

### `tiene_receta` — **decidido: opción A (derivado)**

- Implementación: método o helper p. ej. `Dish#recipe_instructions?` / `has_recipe_instructions?` = `instructions.to_s.strip.present?`. Formularios: bloque de instrucciones colapsable/visible según este predicado (y estado de edición si aplica).
- **Opción B** queda explícitamente fuera salvo nuevo ADR/producto.

### Catálogo público: plato **sin** instrucciones (pregunta 4 — explicación)

Dos enfoques de **solo presentación** (el dato ya permite `instructions` vacío):

| Enfoque | Qué ve el visitante | Pros | Contras |
|--------|----------------------|------|---------|
| **Sección neutra** | Misma página `show`; bloque “Preparación” con mensaje tipo “Sin pasos descritos” o “El autor no añadió preparación detallada”. | Honestidad; sin presión; consistente con ítems simples (p. ej. fruta). | Menos engagement para completar catálogo. |
| **CTA hacia el autor** | Misma página pero CTA solo **para el dueño** autenticado (“Añade preparación para quienes adopten”) o mensaje genérico para todos sin botón destructivo. | Incentiva completar contenido público. | Si el CTA lo ve quien no es autor, puede confundir; hay que condicionar por `current_user` y ownership. |

**Decidido (usuario):** **híbrido** — mensaje **neutro para todos** en el `show` del catálogo cuando no hay instrucciones + **CTA solo para el dueño** autenticado (enlace a editar el plato / añadir preparación), con i18n y sin confundir a adoptantes.

### Bundles `PhaseProgram` y IDs de receta (pregunta 5 — explicación)

**Hecho en código actual:** `PhaseProgramAssignment` asocia **`menu_id`** y **`exercise_routine_id`** por FK (`belongs_to :menu`). No hay columna JSON en `phase_programs` que serialice `recipe_id`. Los platos solo entran **vía** `Menu` → `MenuEntry` → `recipe_id` (pasará a `dish_id`).

**Conclusión:** el refactor **Recipe → Dish** debe tocar **`menu_entries`** (y servicios de menú/adopción), **no** migrar “blobs” en `phase_programs` por IDs de receta incrustados — **no aplican** en el esquema vigente.

**Riesgo lateral:** cualquier **caché**, **vista materializada** o **job** que asuma el nombre `Recipe` en logs/strings no es el mismo problema; un grep global tras el rename sigue siendo obligatorio.

## Rincones oscuros y errores comunes (inventario técnico)

1. **`MenuEntry#entry_content_must_be_present`:** hoy exige `recipe_id` o texto; al renombrar FK (`dish_id` / `plate_id`) hay que actualizar validaciones, Turbo `Menus::UpsertEntry`, `Menus::ContentFingerprint`, specs de adopción/sync.
2. **Adopción y sync:** `Menus::AdoptFromPublicCatalog`, `ApplyAdoptionSourceSync`, `CopyMenuForAdopter`, `DuplicateRecipeForAdopter` — todo el mapa `recipe_id → nuevo id` debe renombrarse y seguir siendo **inyectable** en tests.
3. **Rutas y SEO/libros:** `resources :recipes`, `public_recipes`, rutas anidadas bajo `admin` — decisión de **URLs** (`/platos` vs redirect 301 desde `/recetas`), bookmarks y request specs.
4. **i18n:** claves `activerecord.models.recipe`, menús, catálogo, mails — evitar strings duplicados y namespaces rotos; glosario SPEC en **es/en** alineado.
5. **Migración de datos:** renombrar tabla `recipes` → `dishes`/`plates` implica `menu_entries` FK + índices; **no** llamar servicios de app desde migraciones de datos pesadas (regla **SYSTEM_ARCHITECTURE.md** — lógica congelada en migración o mirror en servicio spec-covered).
6. **`dependent: :destroy` en `Recipe` → menú entries:** mismo comportamiento debe conservarse en el modelo renombrado.
7. **Phase programs / bundles:** solo FK a `Menu`; grep global por `Recipe` / `recipe` en código y specs tras el rename.
8. **Errores comunes:** olvidar `schema.rb` + `SCHEMA_REFERENCE`; olvidar admin revoke; olvidar Stimulus `recipe-image-preview` (nombre de controlador/archivo); asumir `instructions` NOT NULL en DB (hoy es `text` sin `null: false` en schema — OK para vacío, pero validaciones de modelo pueden exigir presencia hoy en forms — verificar `RecipesController` strong params y validaciones).

## Fases propuestas (borrador — no es plan de implementación bloqueado)

| Fase | Contenido orientativo |
|------|-------------------------|
| **F1** | SPEC + glosario: modelo **`Dish`** en código, copy UI “Plato”; ADR si contradice límites de **SYSTEM_ARCHITECTURE.md**. |
| **F2** | Migración esquema: tabla `dishes` (o rename `recipes`→`dishes`), FK `menu_entries.dish_id`, índices; sin alias `Recipe` salvo ventana de deprecación explícita. |
| **F3** | Servicios menú/adopción/fingerprint + `MenuEntry` + specs de servicio. |
| **F4** | Controladores, rutas, vistas, Stimulus, i18n, catálogo `public_*`, admin. |
| **F5** | Limpieza: deprecations, redirects, documentación y seeds/demo. |

## Decisiones cerradas (usuario)

1. **Naming en código:** **`Dish`** (UI “Plato” vía i18n).
2. **URLs:** **Cambio visible** — rutas canónicas nuevas (`/platos`, catálogo público alineado) y **redirect** desde URLs antiguas (`/recetas`, etc.); request specs.
3. **`tiene_receta`:** **A — derivado** de `instructions` presentes (sin columna).
4. **Catálogo público sin instrucciones:** **Neutro para todos** + **CTA solo dueño** autenticado.
5. **Bundles:** sin JSON de recetas en `PhaseProgram`; impacto indirecto vía menús.

## Working notes

- Sesión creada tras confirmación usuario: solo #52, por fases, catálogo incluido.
- 2026-04-27: discovery de producto **cerrado** (incl. 3–4); insertado `<implementation_plan>` para handoff a **start-task**.

<implementation_plan>
  <step id="1" status="complete">Escribir specs que fallen definiendo el comportamiento deseado: redirects desde rutas antiguas de recetas/catálogo hacia rutas `dishes`/`platos`; `public_dishes#show` con plato sin `instructions` muestra copy neutro (i18n) para cualquier visitante; mismo `show` muestra CTA de “añadir preparación” **solo** si `current_user` es el dueño del `Dish`. Ajustar rutas helper en asserts a la convención final elegida en F4. [REQ-MENU-002, REQ-MENU-006]</step>
  <step id="2" status="pending">Migración de esquema: `recipes` → `dishes` (o equivalente), `menu_entries.recipe_id` → `dish_id`, FKs e índices; **sin** lógica de app pesada en la migración (datos mecánicos solo; regla SYSTEM_ARCHITECTURE). Regenerar/actualizar `docs/core/SCHEMA_REFERENCE.md` cuando toque el flujo del repo.</step>
  <step id="3" status="pending">Renombrar modelo **`Recipe` → `Dish`**, asociaciones (`MenuEntry`, `User`, Active Storage), factories y referencias en servicios (`Menus::DuplicateRecipeForAdopter` → nombre `Dish`, `UpsertEntry`, `ContentFingerprint`, adopción/sync, admin). Correr specs afectados hasta verde.</step>
  <step id="4" status="pending">Controladores y rutas: `DishesController`, `PublicDishesController`, admin; parámetros fuertes; Turbo/Stimulus renombrados donde aplique; i18n (`activerecord.models.dish`, catálogo, CTA/neutro). Implementar UI de instrucciones según predicado derivado (A).</step>
  <step id="5" status="pending">Actualizar `docs/core/SPEC.md` (glosario, REQ-MENU-001/002/006 y referencias a **Dish**), `DATA_FLOW_MAP.md` si aplica, seeds/demo, CHANGELOG bajo `[Unreleased]` si hay cambio user-facing. Grep global residual `Recipe`/`recipes_path` en app y specs; RuboCop + RSpec en verde.</step>
</implementation_plan>
