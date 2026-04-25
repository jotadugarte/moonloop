## Task

**Roadmap item:** #46 — Sesiones: textos comprensibles para usuarios no técnicos

**Classification:** Chore

**Description:** En `/sessions`, sustituir o complementar datos crudos (User-Agent, IP `::1`, timestamp UTC) por mensajes claros para usuarios no técnicos: desde qué dispositivo y desde dónde se conectó la sesión, sin exponer IP exacta ni prometer geolocalización no disponible.

<implementation_plan>
  <step id="1" status="pending">Ubicar la vista/controlador de `/sessions` y el origen de `user_agent`, `ip_address`, `created_at`. Definir el formato de “dispositivo” (parse básico de UA) y “ubicación” segura (localhost/red local/“no disponible”).</step>
  <step id="2" status="pending">Agregar/ajustar specs que verifiquen que no se muestra User-Agent crudo ni IP exacta, y que el texto es i18n (es/en) y accesible. [REQ-I18N-001]</step>
  <step id="3" status="pending">Implementar el render de copy claro (helpers/servicio pequeño) y sustituir en la vista, manteniendo privacidad y sin suposiciones.</step>
  <step id="4" status="pending">Correr specs relevantes y RuboCop (solo Ruby) y marcar steps como complete al pasar.</step>
</implementation_plan>

