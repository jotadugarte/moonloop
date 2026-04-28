## Task

**Type:** Bug (regression / incorrect UX vs agreed contract)

**Related roadmap items:** #59 (pending) — Bug: Menús combobox agrupación + filtro; depends on #58 (Done)

**Where:** editor de menú (`/menus/:id/edit`) en el picker/combobox para asignar `Dish` en un slot.

---

## Implementation plan

<implementation_plan>
  <step id="1" status="completed">Write a failing spec that captures the dish picker contract for menu slots (grouping by `meal_type`, group ordering with slot type first then canonical order, and filtering-by-name that preserves groups). Tag with [REQ-MENU-001].</step>
  <step id="2" status="completed">Make the test pass by fixing the dish picker implementation (Stimulus + view partials) so: closed state shows selected dish or “blank”; open state renders grouped options with correct ordering; filter hides non-matches while keeping group headers and shows i18n “no results”.</step>
  <step id="3" status="pending">Add/adjust a11y + i18n wiring for the picker UI (labels, aria, keyboard navigation; ensure `menus.slots.dish_blank` and no-results copy are translated) and cover with a focused spec where appropriate.</step>
  <step id="4" status="pending">Run targeted specs and linters; ensure Turbo autosave flow remains intact (`Menus::MenuEntriesController#create` + slot frame replace) and no slot partial does DB queries.</step>
</implementation_plan>

## Problem statement

La implementación actual del “combo box” para seleccionar plato no cumple el contrato esperado:
- No muestra el estado “sin selección” o el plato seleccionado como valor principal del combobox de forma coherente.
- Al abrir, no presenta una lista completa de platos **agrupada por tipo de comida** con el **grupo del slot primero**.
- Al escribir, no filtra por nombre **manteniendo grupos** como estructura de resultados.

Esto genera una UX confusa y no resuelve el objetivo de “encontrar y elegir plato rápidamente”.

---

## Expected behavior (spec)

### 1) Estado cerrado (sin abrir)
- El control debe mostrar:
  - **Nada seleccionado** (placeholder/label equivalente a “Sin plato”), o
  - el **nombre del plato actualmente seleccionado** en ese slot.

### 2) Al abrir el combobox
- Debe mostrar **todos los platos existentes** del usuario, **agrupados** por `Dish#meal_type` (Desayuno, Almuerzo, Cena, Merienda).
- **Orden de grupos**:
  - Primero el grupo correspondiente al **tipo de comida del slot** (p. ej. si el slot es Desayuno, “Desayuno” arriba),
  - Luego los otros tres en orden fijo: **Desayuno → Almuerzo → Cena → Merienda** (excluyendo el que ya quedó primero).

### 3) Filtrado por escritura
- Al escribir dentro del combobox (campo de búsqueda asociado al control), debe:
  - Filtrar por **nombre de plato** (substring, case-insensitive),
  - Mantener la visualización **agrupada** (solo se ocultan opciones que no matchean; los grupos permanecen con sus matches).

---

## Actual behavior (observed)

Ver captura provista por el usuario: el control se comporta más como una lista mezclada / UI incompleta y no respeta agrupación + filtro como se definió.

---

## Notes / constraints

- No introducir endpoints nuevos de búsqueda si no es necesario; preferir filtro en cliente con Stimulus, manteniendo HTML-first + Turbo autosave.
- Mantener i18n y a11y (labels, foco, navegación con teclado).

---

## Ready for handoff

Este bug está listo para ejecutarse con `start-task` (especificación suficiente: expected vs actual + orden de grupos + filtrado con grupos).

