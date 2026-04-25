## Task

**Roadmap item:** #55 — Registro: orden de campos (peso) (**REQ-PROF-001**)

**Classification:** Chore

**Description:** En `/sign_up`, mover el campo **Peso** para que quede después de **Altura** y antes de **Zona horaria**, preservando comportamiento actual (peso opcional, Turbo 422, métrico/imperial) y sin cambios de copy.

<implementation_plan>
  <step id="1" status="complete">Identificar el/los templates/partials que renderizan Altura, Peso y Zona horaria en `RegistrationsController#new` (y si hay shared partial con Profile) para cambiar el orden sin duplicación.</step>
  <step id="2" status="complete">Escribir/ajustar un spec (request o system según exista) que verifique el orden de los campos en `GET /sign_up` y en el re-render `POST` inválido con status 422. [REQ-PROF-001]</step>
  <step id="3" status="complete">Aplicar el reordenamiento en la vista/partial correspondiente, manteniendo: peso opcional (Done #43), toggle métrico/imperial (altura), y combobox de zona horaria.</step>
  <step id="4" status="complete">Ajustar specs existentes para que no dependan de orden frágil (preferir asserts por label/id) sin expandir scope.</step>
  <step id="5" status="complete">Correr RSpec y RuboCop (y cualquier check del repo) y dejar el step marcado como complete al pasar.</step>
</implementation_plan>

## Notes / Decisions

- Alcance decidido en discovery: aplicar el orden también en perfil **solo si** el formulario comparte el mismo partial; evitar duplicación. Si no es compartido, scope mínimo: solo `/sign_up` (como dice el ROADMAP) y dejar nota de follow-up para perfil.
- Estado: confirmado “verde” tras correr specs/lint localmente.

