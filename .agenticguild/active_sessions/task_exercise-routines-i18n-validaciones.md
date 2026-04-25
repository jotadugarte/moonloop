## Task

**Classification:** Bugfix

**Description:** En `/exercise_routines` con locale `:es`, corregir mensajes de validación mezclados (atributos en inglés como “Exercise routine lines label …”) y claves faltantes (“Translation missing … exercise_routine_lines.invalid”) para que el usuario vea mensajes coherentes en español.

<implementation_plan>
  <step id="1" status="pending">Escribir un request/system spec que reproduzca el bug en `/exercise_routines`: al guardar inválido, no debe aparecer “Translation missing” ni atributos en inglés; los errores deben estar en español. [REQ-I18N-001]</step>
  <step id="2" status="pending">Identificar qué atributos faltan en `es.yml` (p. ej. `exercise_routine.name`, `exercise_routine_line.label`) y qué claves de error faltan (p. ej. `activerecord.errors.models.exercise_routine.attributes.base.empty_routine` o `...exercise_routine_lines.invalid`).</step>
  <step id="3" status="pending">Agregar traducciones faltantes (atributos + errores) con el fix mínimo, evitando cambiar lógica de validación.</step>
  <step id="4" status="pending">Correr el spec del bug y checks mínimos (RuboCop sobre Ruby; YAML load check) y dejar steps como complete al pasar.</step>
</implementation_plan>

