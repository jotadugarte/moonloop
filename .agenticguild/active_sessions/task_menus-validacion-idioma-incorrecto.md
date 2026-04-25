## Task

**Roadmap item:** #56 — Bug: Menús — validación en idioma incorrecto

**Classification:** Bugfix

**Description:** En `/menus`, cuando el locale activo es español, el error de validación de **Nombre** aparece en inglés (“Name can't be blank”). Debe mostrarse coherente con el locale actual (p. ej. español).

<implementation_plan>
  <step id="1" status="pending">Escribir un request/system spec que reproduzca el bug: con locale `:es`, crear/guardar un menú inválido y verificar que el mensaje de error para `name` está en español (y no en inglés). [REQ-I18N-001]</step>
  <step id="2" status="pending">Identificar el origen del mensaje en inglés (i18n no seteado en request, falta de traducción de errores, mensaje hardcodeado, o configuración de load_path).</step>
  <step id="3" status="pending">Aplicar el fix mínimo que haga que las validaciones salgan en el locale activo sin romper otros mensajes (preferir traducciones `activerecord.errors`/`attributes` o seteo correcto de `I18n.locale`).</step>
  <step id="4" status="pending">Correr el spec del bug y un set mínimo de checks (RuboCop + suite relevante) y dejar el step como complete al pasar.</step>
</implementation_plan>

