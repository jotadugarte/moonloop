% Task: public-menu-catalog (ROADMAP **#31**) — **COMPLETED** 2026-04-18
% Archived from `.agenticguild/active_sessions/task_public-menu-catalog.md`

---

# Task: Catálogo público de menús (#31)

**Origen:** `docs/ROADMAP.md` — **Done #31** (catálogo público de menús; paridad **Done #30** / **REQ-EXR-006**).  
**Depende de:** **Done #30** (patrón de producto y referencia de implementación en `ExerciseRoutine` / `PublicExerciseRoutinesController` / servicios `ExerciseRoutines::*`).  
**SPEC:** **REQ-MENU-006** — registro y criterios de aceptación en `docs/core/SPEC.md`.

## Objetivo en una frase

**Catálogo público de menús** con la **misma semántica** que rutinas públicas: opt-in del dueño (`publicly_shareable` ya existe en `menus`), **solo usuarios autenticados** en índice/show/adopción; **autor visible** sin email; **una copia por adoptante por menú origen**; copia **no** auto-actualiza; aviso de cambios, **aceptar actualización** que sustituye **solo el contenido de slots** (entradas); **nombre de la copia** elegido al adoptar **se preserva** al sincronizar; origen borrado, revocado o privado → **origen no disponible** en la copia; **moderación admin** ya cubierta por `Admin::MenusController#revoke_public_share` (ampliar specs al catálogo público si hace falta).

## Contexto técnico (estado actual)

- **`Menu`:** `name_normalized` + unicidad por usuario; `publicly_shareable`; adopción (`source_menu_id`, `source_sync_fingerprint`, `adoption_catalog_origin_id`); servicios `Menus::*` (fingerprint, adopt, apply sync, estado sync); `MenusController` + `PublicMenusController`; catálogo y adopción solo con sesión.
- **`MenuEntry`:** slots únicos; adopción/sync duplican recetas del autor en cuenta del adoptante donde haya `recipe_id`.
- **Admin:** `PATCH /admin/menus/:id/revoke_public_share`; spec de que el menú cae del índice `public_menus` tras revocar.
- **Referencia:** **Done #30** / **REQ-EXR-006**; SPEC **REQ-MENU-006** y `SCHEMA_REFERENCE` alineados.

## Decisiones de producto / dominio (menú)

| Tema | Decisión |
|------|----------|
| Slots con **receta** del origen | En **adopción** y en **apply sync**, para cada `recipe_id` del origen crear (o reutilizar en la misma transacción) una **receta en cuenta del adoptante** que copie nombre/instrucciones/imagen según sea viable; el menú adoptante solo referencia `Recipe` del adoptante. **Deduplicar** por `source_recipe_id` dentro de la misma operación para no duplicar N veces la misma receta origen en varios slots. |
| Slots solo **nota** (`freeform_text`) | Copiar texto tal cual en el menú adoptante. |
| **Phase assignments** del origen | **No** copiar; la copia es solo plantilla de menú (comportamiento alineado a “contenido del menú”, no plan de fases del autor). |
| Unicidad nombre menú por usuario | **Alinear con REQ-EXR / rutinas:** añadir normalización + unicidad por `user_id` si aún no existe, para colisiones claras al adoptar con nombre elegido. |
| Fingerprint | Serialización estable de slots ordenados (p. ej. `weekday`, `meal_type`, `freeform_text`, identidad de receta origen o hash de contenido copiado) — detalle en implementación; patrón análogo a `ExerciseRoutines::ContentFingerprint`. |

## Domain model (CbC) — menú extendido

- **`Menu`:** además de hoy, `source_menu_id` (nullable, self-FK), `source_sync_fingerprint` (string), `adoption_catalog_origin_id` (integer, sin FK, traza tras borrado origen), índice único parcial `(user_id, source_menu_id)` donde `source_menu_id IS NOT NULL`.
- **`has_many :adopted_copies`** con `dependent: :nullify` al borrar origen (mismo patrón que rutinas).
- **Servicios bajo `Menus::`:** `ContentFingerprint`, copiador de estructura de entradas (y orquestación de recetas hijas), `AdoptFromPublicCatalog`, `ApplyAdoptionSourceSync`, `AdoptionSyncStatus` (o nombres alineados con rutinas).

## Riesgos / complejidad

- **Recetas + Active Storage:** copiar receta al adoptante debe ser **transaccional** y testeada (tamaño, permisos, recetas sin imagen).
- **Hotwire grid / UX edición menú:** banners de sync en `menus#edit` sin romper el grid existente.

---

## Handoff

**Estado:** entregado; **#31** en Done en `docs/ROADMAP.md`; **REQ-MENU-006** registrado en SPEC. Cerrar sesión en Guild / archivar cuando proceda.

<implementation_plan>
  <classification>Feature</classification>
  <roadmap_item>31</roadmap_item>
  <summary>Catálogo público de menús con paridad a rutinas públicas (#30): index/show autenticados, autor sin email, adopción con una copia por origen, sync explícito de entradas preservando nombre de copia, origen no disponible, opt-in dueño, moderación admin existente ampliada con cobertura de catálogo.</summary>
  <tdd_mandate>Each step: escribir spec que falle, luego implementación mínima hasta verde; no implementar sin test rojo previo salvo migraciones puras cuando el spec lo exija.</tdd_mandate>
  <steps>
    <step order="1" status="complete">Añadir unicidad de nombre de menú por usuario (normalización tipo `ExerciseRoutine` / `Menu` en SPEC) si falta: migración + validaciones + spec de modelo o request que falle antes y pase después; ajustar seeds/fixtures si rompen.</step>
    <step order="2" status="complete">Request specs catálogo público: `PublicMenusController` (o nombre alineado) `GET` index solo `publicly_shareable`; `GET` show; 404 si no público o revocado; HTML sin email del autor; rutas y controlador mínimos.</step>
    <step order="3" status="complete">Migración: `menus.source_menu_id`, `source_sync_fingerprint`, `adoption_catalog_origin_id`; self-FK; índice único parcial `(user_id, source_menu_id)` WHERE `source_menu_id IS NOT NULL`; `has_many :adopted_copies, dependent: :nullify`.</step>
    <step order="4" status="complete">Specs + servicios: `Menus::ContentFingerprint`; copiador de entradas que duplique recetas al adoptante cuando haya `recipe_id`; `Menus::AdoptFromPublicCatalog` (errores: no público, propio menú, ya adoptado, nombre vacío, colisión nombre).</step>
    <step order="5" status="complete">Specs + `Menus::ApplyAdoptionSourceSync` + banners y `POST accept_source_update` en el controlador de menús del dueño (misma firma de fingerprint esperado que rutinas); casos: pendiente, stale, origen borrado/privado, asignaciones de fase del adoptante no se tocan.</step>
    <step order="6" status="complete">Opt-in `publicly_shareable`: create (index) + `PATCH` update en edición (`menu_params`), i18n es/en, errores con `role="alert"` y `aria_for_field` en formularios; adopción en show público ya estaba en paso 4 — añadido `aria-label` de sección en adopt.</step>
    <step order="7" status="complete">Request spec: tras `revoke_public_share` admin, el menú deja de listarse en `GET public_menus` (`admin_public_sharing_moderation_spec`).</step>
    <step order="8" status="complete">**REQ-MENU-006** en `docs/core/SPEC.md` (registro + criterios); `SCHEMA_REFERENCE` ya citaba REQ-MENU-006 en `menus`.</step>
    <step order="9" status="complete">Cobertura automatizada vía `bundle exec rspec`; humo manual producto (publicar → catálogo → adoptar → sync → revoke) opcional para el operador.</step>
  </steps>
  <out_of_scope>Fase/assignments del autor; notificaciones email; catálogo sin autenticación (mantener paridad con rutinas #30).</out_of_scope>
</implementation_plan>
