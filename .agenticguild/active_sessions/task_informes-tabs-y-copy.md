## Task

**Roadmap item:** #47 — Informes: copy y navegación por pestaña

**Classification:** Chore

**Description:** En `/informes`, ajustar copy y navegación por secciones para cumplir el ROADMAP: quitar la línea “Semana y mes…”, renombrar “Día de referencia” a “Día”, formatear semana como rango legible y mes como “Abril 2026”, y hacer que los enlaces **Cumplimiento · Rachas · Peso** muestren solo la sección activa.

<implementation_plan>
  <step id="1" status="complete">Ubicar la implementación actual de `/informes` (controller + view + helpers) y definir el mecanismo de navegación por sección (links con `?section=` y render condicional server-side). Mantener HTML-first y Turbo-friendly.</step>
  <step id="2" status="complete">Agregar/ajustar specs (request o system) que verifiquen: copy actualizado, formato de semana/mes, y que al cambiar sección solo se renderiza el contenido de esa sección. [REQ-RPT-001, REQ-RPT-002, REQ-RPT-003]</step>
  <step id="3" status="complete">Implementar los cambios de UI/copy/formatos en i18n y vistas (sin hardcode strings) y el render condicional por sección.</step>
  <step id="4" status="complete">Correr specs relevantes y RuboCop (solo Ruby) y marcar steps como complete al pasar.</step>
</implementation_plan>

