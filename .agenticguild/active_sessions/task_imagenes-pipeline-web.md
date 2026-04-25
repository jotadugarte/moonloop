## Task

<session_metadata>
  <roadmap_item>#53</roadmap_item>
  <workflow_classification>Chore</workflow_classification>
</session_metadata>

**Roadmap item:** #53 — Imágenes subidas: formato web pequeño y regla para CRUD futuros

**Classification:** Architecture / Platform rule (cross-cutting)

**Description (user intent):**
Definir una **regla obligatoria y duradera** para toda subida de imágenes (actual y futura) que garantice:
- **Carga rápida** (formatos modernos + tamaños acotados)
- **Uso razonable de almacenamiento**
- **Calidad visual consistente**
- **Aplicación transversal** (no “cada CRUD inventa su propio pipeline”)

---

## What we need to decide (Discovery)

### 1) Format strategy (web + apps)

**Background (what’s most efficient):**
- **AVIF** suele dar **mejor compresión** (menor peso a igual calidad) que WebP/JPEG.
- **WebP** tiene excelente soporte y también comprime muy bien.
- **JPEG/PNG** quedan como compatibilidad/entrada; PNG es pesado para fotos (pero útil para transparencias).

**Propuesta base (pragmática para Rails + Active Storage):**
- **Conservar el original** (por trazabilidad y re-procesado futuro).
- Servir en la UI **variantes web optimizadas**:
  - **Primary**: WebP (siempre).
  - **Optional**: AVIF (solo si el stack de variantes lo soporta de forma segura y mantenible en nuestros entornos).

**Decision (53.Q1): WebP-only (v1).**
- Regla v1: servir variantes optimizadas **solo en WebP**.
- Se conserva el original para re-procesado futuro (si luego queremos AVIF).

### 2) Environments without libvips (current architecture)

`docs/core/SYSTEM_ARCHITECTURE.md` define: variantes requieren **libvips**; sin libvips se debe **servir blob original** (fallback).

**Tensión con #53:** si queremos “normalizar siempre”, entonces:
- O **exigimos libvips** en los entornos donde se procesan imágenes (al menos prod/CI),
- O aceptamos que en algunos entornos **no habrá normalización real** (solo fallback).

**Decision (53.Q2): libvips requerido en producción y CI.**
- **Qué significa**: libvips es la librería del sistema que Active Storage usa para generar variantes (resize/convert).
  - Sin libvips, **no se pueden generar variantes**, y el sistema cae al fallback de “servir blob original”.
- **Por qué exigirlo**: si queremos una “regla obligatoria” (no best-effort), necesitamos que el pipeline sea real en prod y verificable en CI.
- **Dev local**: puede seguir funcionando con fallback si alguien no tiene libvips, pero el contrato del producto se define por prod/CI.

---

## Variant set (thumb / list / detail)

User input: “thumb/list/detail”.

**Propuesta de tamaños (conservadora, suficiente para UI típica):**
- **thumb**: \(160×160\) (square crop o fit según UI; decisión por componente)
- **list**: ancho máx \(640px\) (altura auto)
- **detail**: ancho máx \(1200px\) (altura auto)

**Notas:**
- Esto cubre pantallas “retina” razonablemente: el `detail 1200w` suele verse bien en móvil y desktop sin excederse.
- Si hay UI que realmente necesita hero grande, se añade **un cuarto** tamaño explícito (pero no por defecto).

**Decision (53.Q3): `detail` = 1200px max width.**

---

## Performance targets (weight vs speed)

User intent: “buen target entre peso y rapidez”.

**Propuesta de targets por variante (fáciles de explicar y revisar):**
- **thumb**: objetivo < **20KB** (máx 40KB)
- **list**: objetivo < **120KB** (máx 200KB)
- **detail**: objetivo < **300KB** (máx 450KB)

**Rationale:**
- Estos números suelen mantener LCP razonable y reducen costos de almacenamiento/CDN.
- Son targets; el pipeline debe priorizar **no degradar** demasiado (evitar artefactos fuertes).

**Decision (53.Q4): targets aceptados.**
- thumb: objetivo < 20KB (máx 40KB)
- list: objetivo < 120KB (máx 200KB)
- detail: objetivo < 300KB (máx 450KB)

---

## Scope

User input: “todos los puntos donde la app acepte imágenes actualmente y futuras”.

**Scope rule:**
- Cualquier `has_one_attached` / `has_many_attached` usado para UI pública o autenticada debe:
  - generar variantes estandarizadas,
  - y renderizar imágenes usando el helper/patrón estándar del proyecto.

**Non-goals / guardrails:**
- Solo **imágenes estáticas** (no GIF animado, no video).
- No bloquear uploads por “muy grande”: la expectativa es **procesar/comprimir**.
  - Aun así, por seguridad/operación debemos definir límites “absurdos” para evitar DoS (ver sección Security).

---

## Security / common pitfalls

- Archivos con extensión “.jpg” pero contenido no imagen.
- Imágenes enormes (p. ej. 12000×8000) que explotan CPU/RAM al procesar.
- PNGs fotográficos (pesados) que conviene recomprimir a WebP.
- Orientación EXIF (rotación) si el pipeline no la respeta.
- Transparencia: si hay UI que depende de alpha, WebP/AVIF OK; JPEG no.

**Decision (53.Q7): procesar/comprimir, con límites duros de seguridad.**
- Sí, se pueden convertir a algo más pequeño aunque el original sea pesado: el usuario puede subir grande, pero la UI sirve **variantes** (thumb/list/detail) que son livianas.
- Para proteger CPU/RAM/tiempo de request/job, definimos límites duros:
  - **Max bytes** (por ejemplo 25MB)
  - **Max dimensiones** (por ejemplo 8000px en el lado mayor)
  - Si excede, el upload se rechaza con error i18n (esto es “seguridad”, no UX).

---

## “Where it never gets lost” (documentation placement)

User intent: que sea duradero.

**Propuesta de documentación:**
- Crear `docs/core/IMAGES.md` como **fuente de verdad** (regla + targets + variantes + checklist para futuros CRUD).
- En `docs/core/SYSTEM_ARCHITECTURE.md`, agregar un link explícito en la sección de Active Storage / images.
- (Opcional) En `docs/core/COMPONENT_PATTERNS.md`, documentar el helper de render y cómo elegir `thumb/list/detail`.

**Decision (53.Q8): sí.**
- Crear `docs/core/IMAGES.md` como fuente de verdad.
- Linkearlo desde `docs/core/SYSTEM_ARCHITECTURE.md` en la sección de imágenes/Active Storage.

---

## Next questions to close spec (minimal)

✅ Spec cerrado (decisiones tomadas).

---

<implementation_plan>
  <step id="1" status="complete">Escribir documentación viva: crear `docs/core/IMAGES.md` con la regla obligatoria (WebP-only), el set `thumb/list/detail` (160/640/1200), targets de KB, límites de seguridad (MB/px), y checklist “si agregas un nuevo CRUD con imagen…”.</step>
  <step id="2" status="complete">Linkear la regla desde `docs/core/SYSTEM_ARCHITECTURE.md` en la sección de imágenes/Active Storage para que sea parte explícita de las fronteras del sistema.</step>
  <step id="3" status="complete">Estándar de pipeline: definir un único punto (helper + servicio) para pedir/renderizar variantes `thumb/list/detail` y evitar que cada vista/controller invente tamaños/formats. (Mantener HTML-first; nada de lógica en controllers.)</step>
  <step id="4" status="complete">Implementar normalización WebP en variantes Active Storage para todos los attachments existentes que se usan en UI; asegurar que la app siempre renderiza variantes (no el original) salvo fallback explícito.</step>
  <step id="5" status="pending">Operación: asegurar `libvips` instalado en producción y en CI (documentar el requisito en el README / setup del repo si existe). Mantener fallback local para dev sin libvips (pero CI debe fallar si no puede generar variantes).</step>
  <step id="6" status="pending">Validación de uploads: aplicar límites duros (por ejemplo 25MB / 8000px lado mayor) para proteger CPU/RAM; mensajes de error via i18n; confirmar que solo se aceptan imágenes estáticas.</step>
  <step id="7" status="pending">Pruebas: agregar request/system specs mínimas que verifiquen que el HTML renderiza URLs de variantes (no originales) y que el pipeline produce WebP para `thumb/list/detail`, más un spec para el límite duro (rechazo con 422 + mensaje i18n).</step>
  <step id="8" status="pending">Actualización de CHANGELOG.md bajo `[Unreleased]` (cambio visible de performance/entrega de imágenes + regla transversal) si aplica según la política del repo.</step>
</implementation_plan>

