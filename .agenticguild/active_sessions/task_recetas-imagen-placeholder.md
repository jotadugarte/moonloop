## Task

**Roadmap context:** #54 (scope actualizado) — Recetas: imagen única + placeholder por tipo de comida

**Classification:** Chore (UX/CRUD + reglas de imagen)

## Alcance acordado (locked intent)

- **Una sola imagen por receta** (contrato de producto).
- **Crear receta**: adjuntar automáticamente una **imagen placeholder** según **tipo de comida** (meal type).
- **Subir imagen**: **reemplaza** la imagen actual (placeholder o previa subida).
- **Eliminar imagen subida**: vuelve a adjuntar el **placeholder** correspondiente.

## Reglas / invariantes

- Una receta siempre tiene “imagen actual” (placeholder o subida).
- No deben quedar múltiples adjuntos activos para la misma receta.
- No exponer UI para elegir cuál eliminar (queda obsoleto con contrato de 1 imagen).

## Preguntas abiertas (para terminar discovery)

- ¿Dónde vive el **tipo de comida** de la receta hoy? (en `Recipe` o derivado de otro contexto). Necesitamos una fuente estable para elegir placeholder.
- ¿Cómo se representa el placeholder? (blob en `db/seeds`, archivo estático en assets, o adjunto por defecto ya existente).
- ¿Qué debe pasar con recetas existentes que hoy tienen 0 imagen? (probablemente: mostrar placeholder sin mutar DB, o backfill al editar).

<implementation_plan>
  <step id="1" status="complete">Escribir spec(s) que fallen y capturen el contrato “una sola imagen por receta” y los casos: (a) create adjunta placeholder por tipo, (b) subir imagen reemplaza la actual, (c) eliminar imagen vuelve a placeholder.</step>
  <step id="2" status="complete">Identificar la fuente canonical de “tipo de comida” para una receta y cómo resolver el placeholder correspondiente (sin hardcode strings; usar i18n/constantes si aplica). Documentar decisión en el archivo de sesión.</step>
  <step id="3" status="complete">Implementar “imagen única” en el flujo de create/update: asegurar que al adjuntar una nueva imagen se reemplace la existente; al remover, se restaure placeholder. Mantener comportamiento Turbo 422 y accesibilidad del form.</step>
  <step id="4" status="complete">Actualizar UI en `/recipes/new` y `/recipes/:id/edit` para reflejar el contrato (mostrar “imagen actual”, acción de reemplazar, acción de volver a placeholder). Evitar cualquier UI de “elegir cuál eliminar”.</step>
  <step id="5" status="complete">Correr specs relevantes y RuboCop (solo Ruby) y dejar steps como complete al pasar.</step>
</implementation_plan>

## Decisiones tomadas

- **Fuente canonical de tipo de comida**: `Recipe#meal_type` (persistido, validado contra `Menus::MealType::KEYS`, default `"desayuno"`).
- **Placeholder**: existe como SVG en `app/assets/images/menus/fallback_<meal_type>.svg`.
  - Se adjunta en create / al eliminar imagen subida para mantener el contrato (“siempre hay imagen”).
  - Para evitar errores de serving/variants con SVG, el placeholder se renderiza desde assets cuando el attachment es `fallback_*`.

