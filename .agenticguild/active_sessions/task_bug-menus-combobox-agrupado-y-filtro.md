## Task

**Type:** Bug (regression / incorrect UX vs agreed contract)

**Related roadmap items:** #58 (marked Done) — Menús: combobox por tipo de comida

**Where:** editor de menú (`/menus/:id/edit`) en el picker/combobox para asignar `Dish` en un slot.

---

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

