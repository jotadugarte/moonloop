# Task

**Roadmap item:** #58 — Menús: combobox por tipo de comida

**Classification:** Feature (UX / a11y improvement on existing Hotwire form)

**Docs / REQ anchors:** `docs/core/SPEC.md` (**REQ-MENU-001**, **REQ-MENU-002**). Architecture: `docs/core/SYSTEM_ARCHITECTURE.md` (server-rendered ERB + Turbo; thin controllers; I18n; a11y patterns).

---

## Problem statement

En el editor de menú (`/menus/:id/edit`), cada slot permite elegir un **plato** (`Dish`) mediante un `<select>`. Con una lista larga, encontrar el plato correcto es lento; queremos **agrupar/clasificar** las opciones por **`Dish#meal_type`** (desayuno/almuerzo/cena/merienda) para mejorar escaneo y selección.

---

## Proposed UX (to decide)

### Option A — `<optgroup>` per meal type (preferred if compatible)
- Single `<select>` with `<optgroup label="Desayuno">...</optgroup>`.
- Keeps native select semantics and keyboard support.
- Requires clear ordering and i18n labels.

### Option B — grouped headings (non-optgroup)
- Custom rendering (not recommended unless optgroup is insufficient).
- Higher complexity; risk of a11y regressions.

**Default direction:** Option A, unless constraints appear.

### Option C — Searchable grouped picker (new requirement)
- Add a **name filter** input for the dish picker.
- Results remain **grouped by meal type** while filtering by name.
- Likely requires a small Stimulus controller + a custom list UI (or rebuilding `<select>` options dynamically).
- Higher complexity than `<select>` + `<optgroup>`, but meets the “filter by article name” requirement.

---

## Scope

### In scope
- Menu slot select options grouped by `Dish#meal_type`.
- Deterministic ordering (group order + items order).
- Works with existing autosave (Stimulus `autosubmit` on change) and Turbo slot re-render.
- i18n: group labels, blank option label (“Sin plato” / “No dish”), and any helper copy.
- Specs to lock expected HTML and/or behavior.
- **Name filtering**: user can type to filter by dish name; results stay grouped by meal type; **do not** filter by meal type.

### Out of scope (explicit)
- Server-side search endpoint / remote queries per keystroke (keep it client-side; no new routes).
- Adding new dish attributes, changing persistence, or changing `Menus::UpsertEntry` rules.
- Cross-slot filtering (e.g. “only show dishes matching this slot meal type”) unless decided explicitly below.

---

## Key decisions (need your answers)

1. **Grouping key vs slot meal type**
   - **D1a (group by dish.meal_type only):** show all dishes, grouped by their own `meal_type` (even if it differs from the slot’s `meal_type`).
   - **D1b (also filter to slot meal_type):** show only dishes whose `meal_type` matches the slot `meal_type` (still grouped, but effectively one group).
   - **Recommendation:** D1a (grouping without filtering) to preserve flexibility; filtering can be a later product decision.

2. **Blank option behavior**
   - Keep an explicit blank option at the top (outside groups) for clearing selection.
   - Label via i18n (`menus.slots.dish_blank`).

3. **Ordering**
   - Group order: `Menus::MealType::KEYS` (`desayuno`, `almuerzo`, `cena`, `merienda`).
   - Within group: alphabetical by `Dish#name` (existing `order(:name)`).

4. **A11y**
   - Ensure label `for` matches select id (already in slot partial).
   - Ensure optgroup labels are localized, and no duplicate/confusing labels vs per-slot label.

---

## Decisions (locked)

- **D1 (filtering by meal type)**: **Do NOT filter** to slot meal type. User can search by name; results remain grouped by dish `meal_type`.
- **D2 (blank label)**: **Yes** — use “Sin plato” / “No dish”.
- **D3 (group ordering)**: **Slot meal type group first**, then `desayuno → almuerzo → cena → merienda` (excluding the slot group if already first).
- **D4 (filter matching)**: **Accent-insensitive** (e.g. `cafe` matches `café`) and case-insensitive substring match.
- **D5 (no-results copy)**: Show an i18n “no results” state inside the picker when the filter yields zero matches.
- **D6 (focus behavior)**: After selecting a dish + autosave, move focus to the **next slot** (data-entry flow).
- **D7 (freeform)**: Keep the existing freeform note input; add dish search above it (no unification).

---

## UX contract (draft)

1. Each slot shows a **dish picker** with:
   - a text input to **filter by dish name** (case-insensitive substring match; diacritics policy TBD),
   - a grouped list of matching dishes by `meal_type`,
   - a clear action (blank option / clear button) consistent with existing “Clear slot” flow.
2. Selecting a dish triggers the existing autosave (same request to `Menus::MenuEntriesController#create`).
3. Filtering is purely client-side; no network calls.
4. When the slot Turbo-frame re-renders after autosave, it should:
   - keep the **selected dish** visible and correct,
   - avoid “jumping” focus unexpectedly (keyboard users),
   - move focus to the next slot’s dish filter input (D6).
5. Filter matching:
   - case-insensitive and accent-insensitive substring match (D4),
   - filter applies to dish name only (not meal type).

---

## Domain Model (CbC)

| Entity / VO | Responsibility | Invariants |
|-------------|----------------|------------|
| `Dish` | User-owned item with `meal_type` and `name` used in menu slots | `meal_type` ∈ `Menus::MealType::KEYS`; `name` present |
| `MenuEntry` | Slot row with optional `dish_id` | `dish_id` (if present) belongs to same user as menu |
| `Menus::MealType` (VO) | Canonical meal keys + localization | Only keys in `Menus::MealType::KEYS` |

**Domain Model confirmed:** 2026-04-27

---

## Risks / gotchas

- **Turbo re-render + select state:** ensure `selected:` remains correct when slot replaces itself.
- **optgroup support:** verify Rails helper usage (`grouped_collection_select` / manual `options_for_select`) does not produce invalid markup.
- **i18n namespace:** must use existing `menus.meal_types.*` keys for group labels; no hardcoded strings.
- **Name filter + native select limitations:** hiding/filtering `<option>` across browsers is inconsistent; rebuilding options may lose selection/focus; custom list UI must maintain accessibility.
- **Per-slot persistence of filter query:** if we preserve typed query through Turbo re-render, we need a stable DOM node (likely `data-turbo-permanent`) keyed by slot.

---

## Open questions for you (answer in one message)

1. **Filter matching rules:** should the name filter be **accent-insensitive** (e.g. “cafe” matches “café”)? Default recommendation: **yes** (normalize both sides).
2. **No results state:** what should we show when the filter yields zero matches? (Suggested: i18n “No hay resultados”.)
3. **Keyboard focus:** on selection + autosave, should focus return to the slot container, the filter input, or move to next logical field?
4. **Freeform users:** when `allow_menu_freeform` is enabled, do we keep freeform input as-is (today) and add dish search above it, or fold both into one control?

---

## Notes

- Current slot uses `f.collection_select :dish_id` with a flat list. We will likely switch to an optgroup-based rendering using a Rails helper or building `<option>` tags manually (still server-rendered ERB).
- New requirement adds a **filter-by-name** interaction; we should treat this as a **searchable grouped picker** (Stimulus “sprinkles”) while keeping server-rendered HTML as the source of truth.

---

## Implementation notes (architecture sketch)

**Goal:** meet the name-filter requirement without introducing a new server endpoint and without replacing Turbo autosave.

Recommended approach:
- Render a **per-slot** dish picker that includes:
  - an `<input type="text">` for filter,
  - a grouped list of clickable options (by `meal_type`) rendered from the server with all dishes (for that user) present in the DOM,
  - a hidden `<input name="menu_entry[dish_id]">` (or reuse the `<select>` but likely custom list is needed for reliable filtering),
  - a “clear” affordance that sets `dish_id` blank and triggers submit.
- Stimulus controller (one controller instance per slot) handles:
  - filtering: show/hide option rows and group headings based on input,
  - selection: set hidden `dish_id`, trigger autosubmit (via existing `autosubmit` controller or direct `requestSubmit()`),
  - focus: after Turbo frame update, focus next slot input (requires deterministic next-slot lookup).
- Turbo permanence: use `data-turbo-permanent` for the filter input container if we must preserve typed query during re-render; **BUT** D6 prioritizes moving to next slot, so preserving query is optional (likely not needed).

---

<implementation_plan>
  <step id="1" status="pending">Write a failing system spec (Selenium) for `/menus/:id/edit` that: types into the dish filter, sees grouped results by `meal_type`, selects a dish, observes autosave, and verifies focus moves to the next slot after the Turbo re-render. [REQ-MENU-001, REQ-MENU-002]</step>
  <step id="2" status="pending">Write a failing view/spec (request or view-level assertion) that the picker renders group labels in the expected order: slot meal type first, then the remaining `Menus::MealType::KEYS` order, and includes the “Sin plato/No dish” clear affordance. [REQ-MENU-001]</step>
  <step id="3" status="pending">Implement the grouped searchable dish picker in `app/views/menus/_slot.html.erb` (or extracted partial) using server-rendered grouped option markup and i18n keys. Keep existing freeform field unchanged for freeform-enabled users (D7). Ensure no hardcoded strings.</step>
  <step id="4" status="pending">Add a Stimulus controller for filtering + selection + focus-to-next-slot behavior. Ensure all event listeners are removed in `disconnect()` and rely on `static targets/values` (no global query selectors except scoped within the slot element).</step>
  <step id="5" status="pending">Add i18n keys for: dish-filter placeholder/label, “no results” copy, and any accessibility labels (EN/ES). Reuse `menus.meal_types.*` for group labels.</step>
  <step id="6" status="pending">Make the specs pass; ensure Turbo autosave flow remains intact; run `bundle exec rspec` locally and fix any regressions.</step>
</implementation_plan>

