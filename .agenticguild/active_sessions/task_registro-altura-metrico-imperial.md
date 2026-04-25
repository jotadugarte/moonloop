# Active session: Registro — altura métrico vs imperial

- **Roadmap item:** #45 — Bug: Registro — altura métrico vs imperial (REQ-PROF-003)
- **Classification:** Bugfix
- **Depends on:** Done #40 (posible regresión)

## Problem statement

En `/sign_up` se muestran a la vez el bloque de altura en cm y el bloque imperial (pies + pulgadas). Solo debe mostrarse el conjunto coherente con `body_unit_system`: métrico → solo cm; imperial → solo ft/in. Persistencia sigue siendo `height_cm` canónico.

## Notes (discovery)

- `unit_system_toggle_controller.js` aplica `hidden` en `connect()` y en `change`.
- Los wrappers en `registrations/new.html.erb` no llevan estado inicial en HTML: si Stimulus tarda o no ejecuta, ambos bloques son visibles (FOUC / sin JS).
- SPEC (`REQ-PROF-003`) y glosario ya exigen el toggle; el arreglo es alinear **HTML inicial** con `@user.body_unit_system` (incl. re-render 422).

<implementation_plan>
  <step id="1" status="complete">Write a failing test that reproduces the bug: primera respuesta HTML de registro con `metric` por defecto debe marcar los contenedores `data-unit-system-toggle-target=&quot;imperial&quot;` como ocultos (p. ej. clase `hidden`); con `imperial_us` (simulando re-render), los contenedores `metric` deben ir ocultos y los `imperial` visibles. Usar request spec + Nokogiri o aserción estable sobre el body. Etiqueta [REQ-PROF-003].</step>
  <step id="2" status="complete">Actualizar `app/views/registrations/new.html.erb`: añadir clases condicionales `hidden` (u equivalente Tailwind) en los tres wrappers de altura según `@user.body_unit_system` efectivo (`metric` vs `imperial_us`), alineado con la lógica del Stimulus controller. No duplicar lógica compleja: helper local mínimo o expresión clara en la vista.</step>
  <step id="3" status="pending">Ejecutar specs de registro/request afectados y RuboCop en archivos tocados; ajustar si hace falta. (Comandos los copia el usuario en su terminal.)</step>
</implementation_plan>
