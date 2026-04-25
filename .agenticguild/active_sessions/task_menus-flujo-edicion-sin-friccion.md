<task_session>
  <metadata>
    <task_name>Menús: flujo y edición sin fricción</task_name>
    <type>Feature</type>
    <req_id>[TBD — map to SPEC.md, likely REQ-MENU-001/002 UX surface]</req_id>
    <roadmap_item>#48</roadmap_item>
  </metadata>

  <working_notes>
    ## Goal (from ROADMAP #48)
    - After creating a `Menu` on `/menus` (name only), redirect immediately to `/menus/:id/edit`.
    - On `/menus/:id/edit`, remove per-slot “Guardar” friction:
      - Changing a combobox persists automatically (autosave) for that slot.
      - Show the chosen item’s photo inside each slot control (preview in the grid).

    ## Non-negotiable constraints (SYSTEM_ARCHITECTURE.md)
    - Server-rendered ERB + Hotwire (Turbo/Stimulus), no new Node bundler.
    - Thin controllers; orchestration in services (menus already use `Menus::UpsertEntry`).
    - I18n for user-visible copy; avoid hardcoded strings.
    - For invalid form submissions: render 422 (no redirect) where applicable.
    - Active Storage variants require libvips; fall back to original blob if variants unavailable.

    ## Current architecture anchors (from SPEC/SYSTEM_ARCHITECTURE)
    - Entities: `Menu`, `MenuEntry`, `Recipe` (future rename to “Plato” is roadmap #52; NOT part of this task).
    - Menu slots are persisted sparsely (rows only for filled slots), keyed by `(menu_id, weekday, meal_type)`.
    - Persistence boundary for slot writes: `Menus::UpsertEntry` (preferred entrypoint).

    ## Domain Model (for this task)
    Use existing domain wrappers where they already exist, and avoid raw primitives at service boundaries.

    - `Menus::MealType`
      - Wraps: a canonical meal-type key string
      - Allowed: `Menus::MealType::KEYS` (used by `MenusController#load_menu_editor`)
      - Used for: slot addressing, fallback assets (see `Menus::SlotPreview`)

    - `Menus::Weekday`
      - Wraps: integer weekday 0..6 (Sunday..Saturday)
      - Used for: slot addressing, `MenuEntry#weekday` validation and `Menus::UpsertEntry`

    - `Menus::SlotPreview`
      - Purpose: resolve the slot image display (uploaded recipe image vs meal-type fallback asset path)
      - Contract: `Menus::SlotPreview.call(entry:, meal_type:)` returns `nil` or a `Result` struct

    - Proposed (small new VO, only if it helps keep code explicit)
      - `Menus::SlotKey`
        - Wraps: `weekday` + `meal_type` using `Menus::Weekday` and `Menus::MealType`
        - Purpose: avoid passing `[weekday, meal_type]` arrays around when wiring Turbo Frames / partial locals

    ## Working assumptions (will validate in code)
    - `/menus` create currently redirects to show or index (we will change to edit).
    - `/menus/:id/edit` renders a weekly grid of slots with a select/combobox per slot.
    - Slot changes currently require explicit submit per slot or a full-page “Save”.

    ## Findings (Step 4 — current grid implementation)
    - Edit page: `app/views/menus/edit.html.erb`
      - Builds a 7×meal_types grid and renders each slot via `render "menus/slot"` with locals `menu`, `weekday`, `meal_type`, `entry`.
      - Slot keying matches the existing map: `@entries_by_slot[[weekday, meal_type]]`.

    - Slot partial: `app/views/menus/_slot.html.erb`
      - Each slot is already a **Turbo Frame**: `turbo_frame_tag dom_id(menu, "slot_#{weekday}_#{meal_type}")`.
      - Preview image is already supported via `Menus::SlotPreview.call(entry:, meal_type:)` and `menu_slot_preview_image_tag`.
      - Slot writes currently require an explicit submit button: `f.submit t("menus.slots.save_submit")`.
      - Slot clear is a separate `button_to` hitting `clear_menu_menu_entries_path(menu)` (DELETE) targeting the same frame.
      - **Important**: the partial currently queries recipes directly (`recipes = menu.user.recipes.order(:name)`), which is a view-level DB query we should avoid expanding further; prefer passing `recipes` as a local later if we touch this.

    - Persistence endpoint: `app/controllers/menus/menu_entries_controller.rb`
      - `create` calls `Menus::UpsertEntry.call(**upsert_args)` and responds with:
        - `turbo_stream`: `turbo_stream.replace(slot_frame_id, partial: "menus/slot", locals: ...)`
        - `html`: redirect back to `edit_menu_path(@menu)`
      - `clear` deletes the entry row (if present) and re-renders the slot similarly.
      - On `ActiveRecord::RecordInvalid`, it re-renders the slot with status **422** (turbo) or redirects with an alert (html).

    ## Open questions to resolve during exploration
    - What is the current slot editor UI? (native `<select>`, custom combobox, Turbo Frame per slot, etc.)
    - Slot content supports **both** `recipe_id` **and** `freeform_text` (when `User#allow_menu_freeform` is enabled).
      - **Both may be set at once** for the same slot.
      - **Display rule:** show the **Recipe** name + image when present; show `freeform_text` as a secondary line (or helper text) when present.
      - **Empty-state rule:** if **both** `recipe_id` and `freeform_text` are blank, the slot is considered empty and the persisted `MenuEntry` row should be removed (keep the sparse-table contract).
    - What is the “photo” source for the chosen item?
      - If slot chooses a `Recipe`: use recipe image if present; otherwise meal-type fallback (REQ-MENU-002).
      - If slot is freeform-only: do we show a placeholder image, meal fallback, or no image?
    - What response shape do we want for autosave?
      - Turbo Stream replace the slot partial?
      - Turbo Frame navigation scoped to the slot frame?
      - Optimistic client update + background POST? (Prefer Turbo + server truth)

    ## Risks / tricky bits
    - **Request volume**: autosave on every change must be efficient and idempotent.
    - **Accessibility**: custom combobox must preserve labels, focus, keyboard navigation, and clear save feedback.
    - **Image variants**: preview must not break in envs without libvips; must use the existing “variants available” probe.
    - **Consistency**: keep menu entry persistence path consistent with existing `Menus::UpsertEntry` rules (validation + permissions).
    - **Freeform + autosave**: saving on **blur** avoids a request per keystroke; ensure it still feels responsive and gives clear “saved” feedback.

    ## Candidate approach (not locked yet)
    - Redirect after menu create: `MenusController#create` → `redirect_to edit_menu_path(@menu)`.
    - Autosave per slot:
      - Render each slot as a Turbo Frame; on change, submit a `form_with` targeting that frame.
      - Controller action returns Turbo Stream or frame HTML to re-render slot with updated selection + image.
      - Stimulus “autosubmit on change” controller attached to the select/combobox.
      - For `freeform_text`: save on **blur** (chosen).
    - Slot photo preview:
      - Server renders an `img` (or `attachable_image_tag`) for the selected recipe (or meal fallback).
      - Update happens as part of the slot re-render after autosave.

    ## Acceptance criteria (derived from ROADMAP #48)
    - Creating a menu from `/menus` lands on `/menus/:id/edit` without extra clicks.
    - Changing a slot selection persists without an explicit save button.
    - The selected item’s photo is visible in the slot UI after selection (and on reload).
    - No hardcoded copy; a11y basics upheld; no new forbidden tech.

    ## UX decisions (locked)
    - **Slot content**: supports both `recipe_id` and `freeform_text` (when `User#allow_menu_freeform`).
      - Both may be set simultaneously.
      - Display: recipe name + image primary; freeform text secondary when present.
      - Empty slot: when both are blank, delete the `MenuEntry` row (sparse persistence).
    - **Autosave**:
      - Recipe selection: save on change.
      - Freeform text: save on blur.
      - Feedback: **silent** (no explicit “saved” badge); rely on stable UI and re-render only on server truth.
  </working_notes>

  <implementation_plan>
    <step id="1" status="complete">Write/adjust request specs for menu creation redirect: POST /menus redirects to edit path (302) and is scoped to Current.user. [REQ-MENU-001]</step>
    <step id="2" status="complete">Write/adjust system spec (or request+view spec if already patterned) covering: create menu (name only) → lands on /menus/:id/edit. [REQ-MENU-001]</step>
    <step id="3" status="complete">Locate current /menus create behavior and change redirect target to edit. Ensure invalid create still renders 422 with errors (no redirect). [REQ-MENU-001]</step>
    <step id="4" status="complete">Inventory the current menu edit grid implementation: identify slot partial, persistence endpoint (likely MenuEntries controller) and how it calls Menus::UpsertEntry. Document findings in this session file. [REQ-MENU-001]</step>
    <step id="5" status="complete">Design slot as Turbo Frame boundary: one frame per (weekday, meal_type) that re-renders a single slot partial after save, keeping the page stable. [REQ-MENU-001]</step>
    <step id="6" status="complete">Implement recipe autosave on change: slot form submits to the existing persistence endpoint, targeting the slot frame; server responds with frame HTML (or turbo_stream replace) re-rendering the slot with recipe image preview. [REQ-MENU-001, REQ-MENU-002]</step>
    <step id="7" status="complete">Implement freeform autosave on blur (only when allow_menu_freeform): add a text input/textarea in the slot, and a small Stimulus controller that submits the slot form on blur. Ensure it does not submit per keystroke. [REQ-MENU-001]</step>
    <step id="8" status="complete">Define/implement slot “empty” semantics: if both recipe and freeform are blank, delete the MenuEntry row via service/controller path while keeping UI slot present (empty). [REQ-MENU-001]</step>
    <step id="9" status="complete">Render slot image preview: prefer recipe attached image; else fallback image by meal type; ensure envs without libvips still render by using the existing image-variants availability probe (serve original blob when needed). [REQ-MENU-002]</step>
    <step id="10" status="pending">Add/adjust request specs for slot persistence: change recipe, change freeform (blur), clear both deletes row; all scoped to Current.user; response is Turbo-frame compatible. [REQ-MENU-001]</step>
    <step id="11" status="pending">Accessibility pass on slot controls: label association, focus behavior after frame update, keyboard navigation (especially if custom combobox exists). Keep copy I18n-only. [REQ-I18N-001]</step>
    <step id="12" status="pending">Update docs as needed: ensure the chosen UX is reflected (if there is a relevant living doc section; otherwise update ROADMAP notes only if required by team process). [REQ-MENU-001]</step>
  </implementation_plan>
</task_session>

