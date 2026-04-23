# Registration Bugs (Points 40, 41, 42)

## Description
Resolve three UI bugs/enhancements in the User Registration flow outlined in the Roadmap.

## Requirements

### Point 40: UI Registro - Mostrar/Ocultar inputs de altura
* **Goal**: Show only metric (centimeters) or imperial (feet/inches) height inputs based on the selected `body_unit_system`.
* **Approach**: Implement a Stimulus controller (e.g., `unit-system-toggle_controller.js`) attached to the radio buttons or select for unit system. It will listen for `change` events and toggle the CSS class (e.g., `hidden`) on the respective height input wrappers.

### Point 41: Selección de Zona Horaria
* **Goal**: Replace the static string "America/Costa_Rica" with a real timezone combobox, defaulting to the user's detected location.
* **Approach**: 
  - Use Rails' `time_zone_select` to generate the combobox.
  - Implement a small Stimulus controller (or use a simple inline JS script) to detect the browser's timezone (`Intl.DateTimeFormat().resolvedOptions().timeZone`) and set the combobox value on page load if no value is currently selected.

### Point 42: Etiqueta Sistema Imperial
* **Goal**: Change the UI label from "Estados Unidos pies pulgadas" to "Imperial pies pulgadas".
* **Approach**: Find the view or I18n YAML file where this string is defined and update it.

## Domain Model
No new domain models introduced. These are strictly view-layer and UI interactions.

## Open Questions / Edge Cases
1. **Timezone Autodetection**: Should we allow the user to override the autodetected timezone, and will it persist correctly if they do? (Yes, the combobox allows manual override).
2. **Form Validations**: Do we need to clear the hidden fields when submitting, or does the backend (e.g., `User` model) correctly ignore the height fields of the unselected unit system? (Assumption: The backend already handles this correctly since it's an existing feature, but we will verify during testing).

<implementation_plan>
  <step id="1" status="complete">Write a failing system test (or update existing) asserting that the imperial/metric height inputs correctly toggle visibility when changing `body_unit_system` in the registration form.</step>
  <step id="2" status="complete">Implement `unit-system-toggle_controller.js` and update the registration view to toggle input visibility based on unit selection.</step>
  <step id="3" status="pending">Write a failing system test asserting that timezone selection is a combobox and the label says 'Imperial pies pulgadas'.</step>
  <step id="4" status="pending">Update the registration view to use `time_zone_select` instead of a static string for timezone.</step>
  <step id="5" status="pending">Implement `timezone-autodetect_controller.js` to automatically set the user's local timezone if none is selected.</step>
  <step id="6" status="pending">Update the translation/view files to change the text "Estados Unidos pies pulgadas" to "Imperial pies pulgadas".</step>
  <step id="7" status="pending">Run system tests to verify all registration bugs are resolved and the tests pass.</step>
</implementation_plan>
