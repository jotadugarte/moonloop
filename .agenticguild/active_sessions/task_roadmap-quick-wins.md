## Task

Explorar `docs/ROADMAP.md` con criterio **quick_wins** (bajo esfuerzo / alto valor) y preparar el terreno para pasar a `start-task` por ítem.

## Priorización propuesta (quick wins)

## Orden de ejecución (confirmado)

Orden elegido: **#55 → #56 → #47 → #46 → #54**.

Siguiente a ejecutar: **#55** (Registro: orden de campos).

### 1) #55 — Registro: orden de campos (peso) (REQ-PROF-001)
- **Por qué es quick win**: cambio de UI simple, impacto directo en onboarding.
- **Explorar / decidir**:
  - ¿Solo `sign_up` o también `profile`/otros formularios? (ROADMAP menciona `sign_up` explícito).
  - ¿Mantener el mismo orden en `es` y `en`? (debería ser consistente).
- **Riesgos**: mínimos; cuidar Turbo 422 en errores para no perder estado.

#### Casos (definición de “hecho”) para #55

**Alcance**: `sign_up` **y** perfil (consistencia). El orden aplica igual en `es` y `en`.

- **Caso 55.1 (render inicial GET /sign_up)**:
  - Orden visual: **Altura → Peso → Zona horaria**.
  - Sin cambios de copy/labels; solo reordenamiento.
- **Caso 55.2 (POST inválido → 422)**:
  - Re-render con status **422** (Turbo-friendly) y conserva valores ingresados.
  - El orden se mantiene **Altura → Peso → Zona horaria**.
- **Caso 55.3 (peso vacío)**:
  - Peso sigue siendo opcional (Done #43): dejarlo vacío **no** bloquea el registro.
  - El reorden no rompe la indicación ya existente de “puedes añadirlo luego”.
- **Caso 55.4 (métrico/imperial)**:
  - La UI condicional de altura (cm vs ft/in) sigue funcionando; el orden relativo se mantiene.
  - Peso queda entre altura y timezone, sin duplicar inputs.

### 2) #56 — Bug: Menús — validación en idioma incorrecto
- **Por qué es quick win**: bug visible, probablemente configuración de i18n/validations.
- **Explorar / decidir**:
  - ¿Falla solo en `Menu#name` o en más modelos? (puede ser `activerecord.errors` o `rails-i18n` faltante / default locale).
  - Confirmar cuál es el locale por defecto (SYSTEM_ARCHITECTURE dice `es`) y por qué sale inglés.
- **Riesgos**: bajos; requiere revisar configuración i18n y archivos locales.

#### Casos para #56 (cuando lo ataquemos)
- **Caso 56.1**: Con locale `es` activo, el error de `Menu#name` aparece en español.
- **Caso 56.2**: Con locale `en` activo, el error aparece en inglés.
- **Caso 56.3**: Evitar un “cambio global accidental” que rompa otros mensajes; ajustar lo mínimo necesario.

### 3) #47 — Informes: copy + navegación por pestaña (Cumplimiento · Rachas · Peso)
- **Por qué es quick win**: UI/copy + navegación; valor alto para comprensión.
- **Explorar / decidir**:
  - ¿Tabs con Turbo Frames, anchors con `?tab=...`, o ambos? (preferir HTML-first + Turbo-friendly).
  - ¿Accesibilidad de tabs? (roles, focus, teclado; ver `docs/core/accessibility.md`).
  - Formato de fechas en español (rango semana “20 de abril al 26 de abril de 2026”; mes “Abril 2026”).
- **Riesgos**: medios-bajos; cuidar i18n (sin strings hardcodeadas).

#### Casos para #47 (cuando lo ataquemos)
- **Caso 47.1**: Los links **Cumplimiento · Rachas · Peso** muestran **solo** el contenido de la sección activa.
- **Caso 47.2**: Semana se muestra como rango legible en el locale actual; mes como “Abril 2026” (sin rango día–día).
- **Caso 47.3 (a11y)**: Estado activo discernible y navegación por teclado razonable (sin romper Turbo).

### 4) #46 — Sesiones: textos comprensibles para usuarios no técnicos
- **Por qué es “quick-ish”**: más UX que backend; puede ser incremental.
- **Explorar / decidir**:
  - Qué vamos a mostrar: “Navegador”, “Sistema”, “Ubicación aproximada (si disponible)”.
  - **Privacidad**: evitar mostrar IP exacta; no inferir “desde dónde” sin base (posible: “red local”, “localhost”, o “ubicación no disponible”).
  - Mapeo User-Agent → nombre amigable (tabla mínima).
- **Riesgos**: medios; riesgo de prometer geolocalización que no tenemos.

#### Casos para #46 (cuando lo ataquemos)
- **Caso 46.1**: No mostrar User-Agent crudo; mostrar “Chrome en Windows” / “Safari en iOS” (aprox).
- **Caso 46.2**: No mostrar IP exacta; si no se puede derivar, “Ubicación no disponible”.

### 5) #54 — Editar receta: elegir qué imagen se elimina
- **Por qué es quick-ish**: UX/CRUD puntual.
- **Explorar / decidir**:
  - Contrato: **una sola imagen**. Al crear receta, se precarga una imagen default; el usuario puede reemplazarla subiendo otra.
  - ¿“Quitar imagen” vuelve a default o deja “sin imagen”?
  - Consistencia con regla de imágenes (#53) si se adopta luego.

#### Casos para #54 (cuando lo ataquemos)
- **Caso 54.1**: Siempre hay 1 “imagen actual” (default o subida). Subir una nueva la reemplaza.
- **Caso 54.2**: Si se permite “Quitar imagen”, definir comportamiento: volver a default o quedar sin imagen (pero creación precarga default).

## No “quick wins” (por ahora)

- **#44** seeds/fixtures: valioso pero tiende a crecer; mejor rama dedicada.
- **#52** Receta → Plato: refactor grande + SPEC; no quick win.
- **#53** pipeline de imágenes: arquitectura/ops + doc; no quick win.

## Próximo input que necesito para cerrar esta exploración

1) **Timebox**: flexible (no es constraint).
2) El orden ya quedó confirmado: **#55 → #56 → #47 → #46 → #54**.

## Criterio de alcance (para ejecución rápida)

- Mantener cada ítem como **cambio mínimo** que cumpla el ROADMAP y su REQ.
- Evitar “refactors opportunistic” salvo que bloqueen el cambio.
- Si aparece ambigüedad de producto, preferir el comportamiento más conservador y documentar la decisión.

## Handoff recomendado

Puedes iniciar ejecución con el skill `start-task` sobre **#55** (Registro: orden de campos). Esta sesión queda como discovery/log de decisiones para ese quick win.

## Preguntas abiertas / rincones oscuros (antes de ejecutar)

### Para #55 (reorden de campos en sign_up)
- **55.Q1**: ¿La sección “métricas corporales” está renderizada por un **partial compartido** con perfil? Si sí, ¿aceptamos que el reorden afecte ambos (más consistente) o queremos forzar solo `sign_up` (mínimo alcance)?
- **55.Q2**: ¿El “Peso opcional” (Done #43) incluye un texto/ayuda que depende de la posición del campo? (p. ej. un hint que referencia “arriba/abajo”). Si existe, revalidarlo.
- **55.Q3**: ¿Hay tests (request/system) que asumen el orden actual del DOM? Si sí, acordar que vamos a ajustar asserts para que sean menos frágiles (buscar por label/field id, no por posición), sin expandir el scope.

### Para #56 (validación en idioma incorrecto)
- **56.Q1**: ¿El bug ocurre con locale `es` **real** (no solo default) o solo cuando se fuerza `?locale=es`? (define dónde mirar: `I18n.default_locale` vs `I18n.locale` en request).
- **56.Q2**: ¿El mensaje en inglés viene de:
  - (a) falta de traducciones `activerecord.errors`/`activerecord.attributes`, o
  - (b) locale en request no seteado correctamente, o
  - (c) validación con `message: "..."` hardcodeada?
- **56.Q3**: ¿Queremos “fix mínimo” solo para `Menu#name` o preferimos un fix global (p. ej. cargar rails-i18n / revisar `config.i18n.load_path`) si detectamos que es sistémico?

### Para #47 (tabs en informes)
- **47.Q1**: ¿El estado de tab debe ser **linkeable** (URL con `?tab=streaks`) para compartir/bookmark, o basta con estado en el cliente? (impacta implementación).
- **47.Q2**: ¿Debemos preservar el “día” seleccionado al cambiar tab? (si existe un selector de día).
- **47.Q3**: ¿El contenido de cada tab es pesado (queries/series)? Si sí, conviene lazy-load con Turbo Frames por tab.
- **47.Q4 (a11y)**: ¿Queremos tabs “reales” ARIA (`role="tablist"`) o solo navegación tipo “pills” (links) con contenido condicional? (lo segundo suele ser más simple/robusto en Rails).

**Decisión recomendada para #47**: hacerlo **linkeable** con `?tab=...` y construirlo como **links** (no ARIA tablist) que renderizan condicionalmente una sola sección. Es HTML-first, shareable/bookmarkable y simple de testear.

### Para #46 (sesiones, lenguaje claro)
- **46.Q1**: ¿Tenemos una fuente confiable de “desde dónde” (geoip) en el stack? Si no, definir copy seguro: **“Ubicación no disponible”** o “Red local” para `::1`/`127.0.0.1`.
- **46.Q2**: ¿Qué nivel de detalle es aceptable para privacidad? (no IP exacta; ¿mostrar ciudad/país si existiera?).
- **46.Q3**: ¿Cómo definir “dispositivo actual” (la sesión que estás usando ahora) para destacarla? (si aplica).

### Para #54 (elegir imagen a eliminar)
- **54.Q1 (resuelto)**: Contrato: **una sola imagen**; siempre hay default al crear, y se reemplaza al subir otra.
- **54.Q2 (resuelto)**: “Quitar imagen actual” **revierte a la imagen default** (mantener contrato “siempre hay imagen”).

## Referencias

- ROADMAP: `docs/ROADMAP.md` (sección “Pending (by priority)”).
- Arquitectura: `docs/core/SYSTEM_ARCHITECTURE.md` (i18n `es`, Turbo 422, HTML-first).

