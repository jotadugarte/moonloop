# Task: Recipe images — Roadmap #51 + #50

**Branch (roadmap):** un solo branch para ambos (imágenes de receta / Active Storage).  
**Roadmap:**

- **#51** — Bug: en `/recipes/:id`, la imagen subida no se muestra (icono “imagen no encontrada”).
- **#50** — En `/recipes/new`, al adjuntar imagen, feedback inmediato en la página (vista previa / sensación de “subida”; mismo branch que #51).

**REQ traceability:** `REQ-MENU-002` (recetas: nombre, instrucciones, imagen opcional).

<roadmap_item>docs/ROADMAP.md — Pending **#51** (detalle de receta sin imagen), **#50** (vista previa en nueva receta); mismo branch; confirmado por usuario.</roadmap_item>
<classification>Mixed: **Bugfix** (#51) + **Feature** (#50).</classification>

---

## Code anchors (estado actual del repo)

- **`Recipe`:** `has_one_attached :image` (`app/models/recipe.rb`).
- **`RecipesController#show`:** usa `set_recipe` con `includes(image_attachment: :blob)`; vista `app/views/recipes/show.html.erb` renderiza imagen con `attachable_image_tag` si `image.attached?`.
- **Formulario:** `app/views/recipes/_form.html.erb` — `file_field :image`; bloque de miniatura solo si `@recipe.image.attached?` (en **new** nunca hay adjunto hasta guardar).
- **`ApplicationHelper#attachable_image_tag`:** si `attachment.variable?` → `variant(resize_to_limit:)`; si no → blob original. `image_tag source, **image_options`.
- **Gems:** `image_processing` presente en `Gemfile` (variantes raster).
- **Specs:** `spec/system/recipes_crud_spec.rb` crea receta con SVG fixture y espera `img[alt=...]` en detalle; `spec/requests/recipes_crud_spec.rb` adjunta SVG por multipart. No cubren explícitamente JPEG/WebP ni fallo de `src`.

---

## Hipótesis — #51 (detalle sin imagen)

1. **Variantes raster sin procesador nativo:** si el usuario sube JPEG/PNG, `variable?` es true y se pide variante; sin **libvips** (o ImageMagick) operativo en el host, la URL de representación puede responder **500** o fallar → navegador muestra imagen rota. (Con SVG, el spec usa no-variable y sirve el blob; el bug podría no reproducirse con solo SVG en CI.)
2. **`img src` / rutas Active Storage:** comprobar en navegador si el `GET` a `rails/active_storage/representations/...` o `.../blobs/...` devuelve 404/403/500 frente a 200.
3. **Menos probable aquí:** CSP (initializer comentado); `default_url_options` solo explícito en mailer — en vistas HTTP suele bastar `request` para URLs relativas.

**Acción de diagnóstico sugerida (humano o start-task):** reproducir con PNG/JPEG; inspeccionar red + logs al cargar el detalle.

---

## Alcance — #50 (vista previa en new)

- **Hoy:** no hay lógica de preview antes de `create`; el archivo solo llega al servidor en el POST.
- **Opciones:**
  - **A — Solo cliente:** Stimulus (o `URL.createObjectURL` + revocar en `disconnect`) para mostrar la imagen elegida **sin** subida hasta enviar el formulario. Cumple “feedback inmediato” sin cambiar contrato HTTP.
  - **B — Direct upload:** Active Storage direct upload al seleccionar archivo; más trabajo (signed blob, progress, limpieza de huérfanos) y encaja si el producto exige “ya está en el servidor” antes de crear la receta.

**Recomendación de descubrimiento:** empezar por **A** salvo que negocio exija persistencia previa al `Recipe`.

---

## Domain model (CbC)

| Entity / concern | Responsibility | Invariants |
|------------------|----------------|------------|
| **Recipe** | Plato del usuario; datos y opt-in público | Pertenece a `user`; `name` presente; imagen opcional |
| **ActiveStorage::Attachment (`image`)** | Binario asociado a la receta | Si attached, blob existe en servicio configurado (`:local` en dev/prod según `storage.yml`) |
| **Variant (resize_to_limit)** | Derivado visual para raster | Solo para `variable?`; requiere pipeline `image_processing` + nativo en sistema |

**Value objects:** ninguno nuevo obligatorio; límites MIME/tamaño podrían documentarse si se endurecen validaciones (fuera del mínimo de este par).

## Domain Model

**Aprobado (start-task 3.0):** sin value objects nuevos respecto a la tabla anterior. Entidades vigentes: **Recipe**, adjunto **Active Storage (`image`)**, **Variant** `resize_to_limit` para blobs `variable?`.

---

## Riesgos y restricciones

- **`docs/core/SYSTEM_ARCHITECTURE.md`:** Hotwire/Stimulus sí; sin jQuery; i18n para copy nuevo (#50).
- **Turbo:** preview en `new` no debe romper envío del formulario ni accesibilidad (etiqueta/alt desde nombre provisional o cadena i18n genérica hasta tener `name`).
- **Tests:** bugfix #51 debe poder demostrarse con **test que falle antes del fix** (request o system según dónde falle la URL o la respuesta).

---

## Preguntas abiertas (cerradas para implementación)

1. **#51:** cubrir raster (p. ej. PNG) en tests; si el fallo es solo entorno, el test documenta el contrato “URL de imagen en show debe responder OK”.
2. **#50:** **vista previa solo cliente** (opción A); sin direct upload salvo decisión posterior explícita.
3. **Validación extra de MIME/tamaño:** fuera del alcance mínimo de este branch salvo que el fix lo requiera.

---

<implementation_plan>
  <title>Roadmap #51 + #50 — Imagen en detalle de receta y vista previa en nueva receta</title>
  <req_traceability>REQ-MENU-002</req_traceability>
  <architecture_alignment>docs/core/SYSTEM_ARCHITECTURE.md — ERB + Hotwire/Stimulus, sin jQuery; Active Storage local; service/helper patterns ya existentes.</architecture_alignment>

  <phase order="1" id="bug-51" name="Detalle de receta: imagen visible">
    <step order="1">Write a failing test that proves the bug contract: with a signed-in user, create a `Recipe` whose `image` attaches a **raster** fixture (e.g. minimal PNG/JPEG under `spec/fixtures/files/`, add file if missing). `GET` `recipe_path(recipe)`, parse the first recipe hero `img[src]` from the HTML, then `GET` that path (following redirects as Rack::Test allows) and assert **HTTP success** and a raster-ish response (e.g. `200`, body non-empty; optionally `content_type` image/*). This should fail in the broken scenario (broken variant pipeline or bad URL) and become the regression guard.</step>
    <step order="2">If the test fails as expected, diagnose: server logs and response code for the Active Storage representation/blob URL. Classify: missing native image processor (libvips/ImageMagick), mis-generated URL, authorization, or other.</step>
    <step order="3">Implement the minimal fix consistent with `SYSTEM_ARCHITECTURE` and `ApplicationHelper#attachable_image_tag` usage elsewhere: e.g. ensure variant processing works in target environments **and/or** a safe fallback when variants cannot be generated (serve original analyzable blob for display only, without weakening authorization). Avoid fat controllers; keep URL generation in helpers/views as today.</step>
    <step order="4">Run the new/updated specs plus existing `spec/requests/recipes_crud_spec.rb` and `spec/system/recipes_crud_spec.rb`; iterate until green.</step>
    <step order="5">If the fix is user-visible beyond an invisible correction, add a line under `[Unreleased]` in `CHANGELOG.md` referencing recipe image display.</step>
  </phase>

  <phase order="2" id="feature-50" name="Nueva receta: vista previa de imagen">
    <step order="1">Write a failing test first: extend or add a system example that uses **`driven_by(:selenium_chrome_headless)`** (pattern already in `spec/system/registration_spec.rb`) for `visit new_recipe_path`, attach a raster file to `recipe[image]`, and **before** clicking submit assert a visible preview image (stable selector, e.g. `data-test` or role) with appropriate `alt` from i18n. Without the Stimulus behavior, this must fail.</step>
    <step order="2">Register/import a small Stimulus controller on the recipe form wrapper: on file input `change`, if a file is present, set preview `img.src` via `URL.createObjectURL`, show the preview container; on `disconnect` revoke object URLs to avoid leaks. Match existing Stimulus/importmap conventions.</step>
    <step order="3">Update `app/views/recipes/_form.html.erb` (and only related partials) to mount the controller, add preview markup hidden until a file is chosen, and use **i18n** for any new user-visible strings (preview alt/aria). Follow `docs/core/accessibility.md` (label association, avoid icon-only without `aria-label` if applicable).</step>
    <step order="4">Green the new system spec; keep rack_test-based examples unchanged unless they need the same form markup without JS regressions.</step>
    <step order="5">Add `[Unreleased]` `CHANGELOG.md` entry for the preview UX.</step>
  </phase>

  <phase order="3" id="closure" name="Cierre de branch">
    <step order="1">Run full targeted suite (`recipes`, `application_helper` if touched) and RuboCop on touched files.</step>
    <step order="2">Update `docs/ROADMAP.md` checkboxes for #51 and #50 when shipped on the branch (per project habit); no SPEC change unless REQ text is extended.</step>
  </phase>
</implementation_plan>
