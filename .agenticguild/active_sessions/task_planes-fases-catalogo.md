# Task: planes-fases-catalogo

## Roadmap item
- #61 — Planes + Fases reutilizables (catálogo + adopción + sync) + rename real + corte total

## TL;DR (user intent)
El usuario quiere un constructor de **Planes** donde:
- Un **Plan** se compone de varias **Fases** (reutilizables, no necesariamente “pegadas” entre sí).
- Cada **Fase** tiene duración (semanas) y asigna **menús** y **rutinas de ejercicio** por semana (o como bloque).
- El usuario puede:
  - Crear sus propios planes / fases / menús / rutinas.
  - Armar un plan completo de forma intuitiva.
  - Elegir planes precargados desde un **catálogo público**.

## Anchors del repo (NO inventar)
En `docs/core/SPEC.md` ya existe el concepto **Phase program (bundle)**:
- `PhaseProgram`: “template shareable” que agrupa planificación coordinada de **menús + rutinas** para **program weeks** (contiguas) bajo **REQ-PHS-001**.
- Catálogo público y adopción/sync ya existen para `PhaseProgram` (**REQ-CAT-001**, **REQ-PHS-001**).

**Hipótesis actual (a validar):** lo que el usuario llama “Plan” ≈ `PhaseProgram` existente, pero el usuario también quiere **Fases reutilizables** como “bloques” dentro de un plan, y hoy el sistema parece modelar “segmentos por rango de semanas” (p.ej. `phase_program_assignments`) pero NO necesariamente como entidad reutilizable con nombre.

## Objetivos (A+B+C)
- **A (Modelo):** soportar Plan → Fases reutilizables → asignaciones menú/rutina.
- **B (UX):** que usuario cree y arme planes/fases/menús/rutinas fácil e intuitivo.
- **C (Catálogo):** planes precargados (públicos) seleccionables (adoptables).

## No-objetivos (por ahora, si no se decide lo contrario)
- Catálogo anónimo (SPEC dice autenticado).
- Analytics de “vistas” del catálogo (SPEC lo excluye).
- Reemplazar stack (Hotwire/ERB), Node bundler, etc.

## Domain Model (Value Objects / types)
- `ProgramWeekIndex`: entero \(>= 1\). Se calcula desde `users.phase_one_starts_on` y el día local del usuario vía `Phases::WeekNumber`.
- `WeeksCount`: entero \(>= 1\) para duraciones de fases/bloques en semanas completas.
- `WeekRange`: rango inclusivo `(start_week..end_week)` con `start_week >= 1` y `end_week >= start_week`.

### Invariantes de bloques dentro de una Phase
- **Cobertura total**: los bloques de **menú** y **rutina** deben cubrir exactamente `weeks_total`.
- **Secuencial sin huecos**: los `WeekRange` internos son contiguos y no dejan semanas vacías.
- **Sin solapes**: los `WeekRange` internos no se pisan.
- **Paridad de lanes**: toda semana cubierta debe tener **menú y rutina** (sin semanas con uno solo).

## Domain Model (CbC)

### Entity: Plan (posible `PhaseProgram`)
- **Responsabilidad:** representar un programa completo de N semanas compuesto por fases/segmentos.
- **Invariantes:**
  - Tiene un **owner** (usuario).
  - Tiene una duración total derivada de sus fases/segmentos.
  - No debe tener rangos de semanas **solapados** dentro de su propio set de segmentos.
- **Value objects sugeridos (si aparecen en la implementación):**
  - `ProgramWeekIndex` (ya existe como concepto; week math en `Phases::WeekNumber`).

### Entity: Phase (nuevo o “segmento nombrado”)
- **Responsabilidad:** bloque reutilizable (p.ej. “acostumbramiento”) con duración y asignaciones.
- **Invariantes:**
  - Duración en semanas \(>= 1\).
  - Debe ser “aplicable” a un plan sin ambigüedad (cuando se inserta en un plan, define qué pasa en esas semanas).
  - Si permite asignaciones por sub-rangos internos, estos tampoco deben solaparse.
- **Decisión cerrada:** dentro de una fase, **cada semana puede tener menú y rutina diferente**, pero siempre en **semanas completas**.
  - Menús y rutinas se agregan como **bloques** de 1..N semanas (sin semanas parciales).
  - Una fase de 4 semanas puede tener, por ejemplo: 4 menús de 1 semana, o 2 menús de 1 semana + 1 menú de 2 semanas (y lo mismo para rutinas).
  - **Invariante adicional:** los bloques dentro de la fase deben ser **secuenciales y sin huecos** y cubrir exactamente `phase.weeks_total`.

### Entity: PlanPhase (composición)
- **Responsabilidad:** unir un Plan con una Phase, incluyendo orden y/o ubicación.
- **Invariantes:**
  - Define posición: por **orden** (secuencial) o por **start_week** explícito.
  - Si se permiten “gaps”, deben ser intencionales y visibles en UI.

### Entity: Menu / ExerciseRoutine
- Ya existen con catálogos públicos y adopción/sync (REQ-MENU-006, REQ-EXR-006).

## UX: flujos esperados (borrador)
- **Biblioteca de Fases:** crear fase con nombre, semanas, asignación de menú/rutina, tags/dificultad (si aplica).
- **Constructor de Plan:** seleccionar 1..N fases (arrastrar/ordenar), ver duración total, preview por semanas.
- **Publicación:** publicar plan al catálogo (si es `PhaseProgram` ya aplica), con metadata (tags, dificultad, weeks).
- **Adopción:** adoptar plan del catálogo → crear copia editable del usuario (paridad con `PhaseProgram` actual).

## Preguntas de aclaración (para cerrar “rincones oscuros”)
1. **Fase interna:** dentro de una fase de 4 semanas, ¿el menú/rutina es fijo para las 4, o cambia por semana (p.ej. semana 1 menú A, semana 2 menú B)?
2. **Secuencia vs posiciones:** cuando armas un plan, ¿siempre se calcula secuencialmente (fase1 ocupa semanas 1..4, fase2 5..10) o el usuario puede colocar una fase en semanas específicas (con huecos)?
3. **Reutilización:** ¿una fase se reutiliza “por referencia” (si la edito, cambia en todos los planes) o “por copia” (snapshot al agregarla a un plan)?
4. **Catálogo de fases:** además del catálogo de planes, ¿quieres catálogo público de **fases** (bloques) para mezclar y armar planes?
5. **Coherencia con “anchor”:** hoy la semana de programa depende de `phase_one_starts_on` del usuario. ¿Aplicar un plan significa “reemplazar mis asignaciones actuales” y reiniciar/ajustar anchor? (REQ-PHS-001 sugiere “apply bundle replaces assignments”.)
6. **Permisos:** ¿el usuario puede compartir planes/fases sin publicarlos (link privado), o solo catálogo público autenticado?

## Casos extremos / errores comunes (checklist)
- **Solapes**: fases que se pisan por semana (debe bloquearse o auto-arreglarse).
- **Huecos**: semanas sin asignación (¿permitidas? ¿cómo se ven?).
- **Edición posterior**: editar una fase que ya está en planes; riesgo de cambios inesperados.
- **Borrados**: borrar menú/rutina usados por una fase/plan (qué fallback/errores).
- **Adopción + sync**: el usuario adopta un plan y luego el autor lo cambia; ¿sync actualiza fases? ¿o solo el plan “source” y el usuario decide aplicar?
- **Inconsistencia de lanes**: menus vs routines tienen carriles independientes en `/phase` (regla repo #15); el builder de plan no debe colapsar estado.
- **Duración**: cambios de duración (p.ej. fase de 4→6 semanas) y cómo re-fluye el resto.
- **i18n**: nombres/descripciones son user-generated; etiquetas UI no.
- **Bloques internos inválidos**: suma de semanas < o > que la duración de la fase; o “bloque 0 semanas”.
- **Desalineación menú vs rutina**: si en una fase los bloques de menú cubren 4 semanas pero los de rutina cubren 3 (debe bloquearse o forzar completar).
- **Re-uso snapshot + actualizaciones**: cómo presentar “actualizar fase en planes” cuando el plan ya es snapshot.
- **Semanas vacías**: el usuario definió que NO se permiten semanas sin menú o sin rutina (debe validarse).

## Decisiones pendientes (lo más importante)
1. **¿“Plan” es `PhaseProgram` existente o un nuevo modelo?**
2. **¿“Fase” es nuevo modelo reutilizable o un “segmento” nombrado dentro de `PhaseProgram`?**
3. **¿Reutilización por referencia vs snapshot?** (impacta UX + sync + consistencia)
4. **Adopción de fase pública**: al adoptar una fase desde catálogo, ¿qué pasa con los menús/rutinas que referencia?
5. **Aplicar plan al usuario + anchor**: reemplazo total con advertencia; sugerir “hoy” y usuario elige.
6. **Borrado de menús/rutinas usados**: definir comportamiento para proteger invariantes.
7. **Sync UX**: ver cambios (diff) antes de aplicar.
8. **Nomenclatura**: alinear nombres en código y docs (Plan/Fase reflejados en modelos/terminología).
9. **Rename real vs alias**: decisión explícita para renombrar `PhaseProgram` a `Plan` (y modelar `Phase` como entidad first-class).

## Next (en este discovery loop)
- Elegir nomenclatura final: Plan/Phase vs PhaseProgram/Segment.
- Definir invariantes definitivos (solapes, huecos, variación semanal).
- Alinear con REQ existentes: `REQ-PHS-001`, `REQ-CAT-001`, `REQ-EXR-*`, `REQ-MENU-*`.

## Respuestas del usuario (cerradas)
- **Composición de fases en plan**: **secuencial**, el usuario puede **cambiar el orden** durante la creación. **Sin huecos**.
- **Reutilización**: **snapshot/copia**. El plan queda estable.
  - UX esperado: informar “esta fase está siendo usada en X planes” y ofrecer una opción explícita para “actualizar automáticamente” (esto implica un mecanismo de “re-aplicar snapshot” o “sincronizar desde fase fuente”, no cambios silenciosos).
- **Catálogo público**: se requieren catálogos públicos para **Menús**, **Rutinas**, **Fases** y **Planes**.
- **Cobertura total por semana**: toda semana dentro de una fase debe tener **menú y rutina** (sin semanas vacías).
- **Actualización all-or-nothing**: cuando se decide “actualizar”, se aplica a **todos** los planes/copias del usuario que correspondan (no selección por plan).
  - Se debe seguir el patrón de catálogo: cuando el “source” cambia, los consumidores reciben aviso para decidir aplicar la actualización.
- **Adopción de fase pública**: **Opción A (copiar todo)**.
  - Al adoptar una fase desde catálogo, se **duplica**: fase + todos los menús/rutinas referenciados (y sus contenidos) para el adoptante.
  - En el catálogo el usuario puede ver el **detalle completo** de la fase (incluye menús/rutinas por semana/bloque).
- **Aplicar plan al usuario**: **sí, reemplaza todo**, con **advertencia previa**.
- **Anchor al aplicar**: se **sugiere hoy** (en zona del usuario) y **el usuario elige**.
- **Sync UX**: siempre **ver cambios** (diff) y luego **aplicar update**.
- **Nomenclatura**: alinear **código y docs** (evitar divergencia entre UI y modelos).
- **Borrado desde Menus / ExerciseRoutines**: no se permite borrar si está referenciado por una Fase/Plan; UX: “**debes editar la fase primero**” (o remover/reemplazar el bloque que lo usa) y luego borrar.
- **Borrado de una Fase**: si está usada en X planes, **bloquear**. Flujo requerido: **duplicar y desvincular** primero (los planes quedan con su snapshot; la fase original no puede desaparecer mientras tenga dependientes).
- **Rename real**: se prefiere **renombrar de verdad** en código/docs (no solo labels en UI).
- **Compatibilidad**: **CORTE TOTAL**. Sin aliases/redirects para rutas/URLs antiguas (`phase_program*`, `public_phase_programs`, etc.). El cambio debe ser atómico.

## Impacto del “rename real” (para que no se escape nada)
- **Renames de modelos/tablas**: `PhaseProgram` → `Plan` (y sus asociaciones/servicios/rutas), más la introducción de `Phase` como entidad reutilizable.
- **Servicios**: `Programs::*` probablemente se renombra a `Plans::*` (o equivalente), cuidando compatibilidad de rutas y referencias internas.
- **Catálogo**: `public_phase_programs` se convierte en `public_plans` (o alias temporal) y se extiende a catálogo público de **fases**.
- **Adopción/sync**: paridad con los flujos existentes (REQ-PHS-001 / REQ-CAT-001) pero adaptados a “fase” como unidad adoptable (copiar todo).
- **Datos existentes**: se requiere plan de migración para no romper usuarios actuales (migraciones + backfills + redirects de rutas si aplica).
  - Con **corte total**, los redirects/aliases NO aplican: actualizar referencias en una sola entrega.

## Roadmap note (post-MVP / decisión del usuario)
- El usuario quiere que **un “menú” (como template)** pueda opcionalmente representar **1..N semanas** (y análogo para rutinas). Marcar para roadmap como mejora posterior (no bloquear el diseño de “Fases”).
  - Nota: hoy, en el repo, `Menu` y `ExerciseRoutine` son **semanales** (se planifican por semana). Esta extensión impacta adopción/sync y cómo se aplican bloques repetidos.

<implementation_plan>
  <classification>Feature</classification>
  <anchors>
    <doc path="docs/core/SYSTEM_ARCHITECTURE.md" />
    <doc path="docs/core/SPEC.md" />
    <doc path="docs/core/DATA_FLOW_MAP.md" />
    <doc path="docs/core/SCHEMA_REFERENCE.md" />
    <doc path="docs/ROADMAP.md" />
  </anchors>

  <decisions_locked>
    <decision id="D1">Plan = renombrar de verdad el concepto hoy llamado `PhaseProgram` (rename real) y alinear docs/código; CORTE TOTAL (sin redirects/aliases).</decision>
    <decision id="D2">Plan se compone de Fases reutilizables; al crear Plan se ordenan secuencialmente sin huecos; usuario puede reordenar.</decision>
    <decision id="D3">Fase contiene bloques internos por rangos de semanas completas (1..N); puede variar menú/rutina por semana/bloque; bloques secuenciales sin huecos que cubren exactamente `weeks_total`.</decision>
    <decision id="D4">Toda semana de la fase debe tener menú y rutina (sin semanas vacías).</decision>
    <decision id="D5">Reutilización snapshot/copia: al agregar una fase a un plan, se copia (plan estable). “Actualizar” es all-or-nothing con aviso y diff.</decision>
    <decision id="D6">Catálogo público autenticado para Menús, Rutinas, Fases y Planes; adoptar una Fase pública copia todo (fase + menús + rutinas referenciados).</decision>
    <decision id="D7">Aplicar Plan al usuario reemplaza todas las asignaciones actuales (con advertencia previa). Anchor sugerir “hoy” y usuario elige.</decision>
    <decision id="D8">Borrados: no borrar menú/rutina si está referenciado (debe editar la fase primero). No borrar fase usada por planes; flujo: duplicar y desvincular.</decision>
    <decision id="D9">Sync UX: ver cambios (diff) antes de aplicar update.</decision>
  </decisions_locked>

  <scope_notes>
    <note>Existe funcionalidad implementada para bundles/catalog bajo `REQ-PHS-001` y `REQ-CAT-001`. Este trabajo reestructura el dominio para introducir Fases reutilizables como unidad first-class y renombra “phase program” a “plan”.</note>
    <note>Roadmap: “menú/rutina como template multi-semana (1..N)” se deja para trabajo posterior; en este plan, menú/rutina siguen siendo semanales, y los bloques de fases operan repitiendo/encadenando semanas completas.</note>
  </scope_notes>

  <plan>
    <step id="S1" status="complete">Write failing request specs for the new public catalogs endpoints shape: `public_plans`, `public_phases` index/show require authentication and render no PII author fields, mirroring existing catalog behavior (REQ-CAT-001 patterns).</step>
    <step id="S2">Write failing service specs for adoption of a public Phase: “adopt copies everything” (phase + referenced menus + referenced routines + block structure), and increments catalog counters exactly once per source per adopter (REQ-CAT-001 adoption counters).</step>
    <step id="S3">Write failing service specs for “apply plan to user” behavior: replaces all existing week-range assignments (menus + routines) and requires explicit anchor date selection (suggest default “today in user TZ” but persist user choice).</step>
    <step id="S4">Introduce new domain models for reusable phases and their internal block assignments (menu blocks and routine blocks) with validations: weeks_total >= 1; blocks sequential, cover exactly weeks_total; no gaps; no overlaps; every week has both menu and routine coverage.</step>
    <step id="S5">Implement Plan composition via “plan phases” that snapshot/copy phase structure into the plan. Enforce sequential ordering and compute total weeks deterministically.</step>
    <step id="S6">Implement public catalog for phases: listing filters/sort parity with REQ-CAT-001 where applicable; detail page shows full phase breakdown (menus/routines by blocks/weeks). Add moderation revoke parity.</step>
    <step id="S7">Implement adoption/sync for phases: adopt copies all nested content; sync status + diff generation for “ver cambios” UI; apply update is all-or-nothing for all relevant copies, and never silent.</step>
    <step id="S8">Rename `PhaseProgram` → `Plan` and `Programs::*` → `Plans::*` (and any `public_phase_programs` routes/controllers/views) with CORTE TOTAL: update all references in routes, controllers, services, views, tests, and docs in the same change set; no redirects.</step>
    <step id="S9">Update `/phase` (plan overview) UX to include Plan + Phase builder entry points without violating “independent assignment lanes” rule: menu lane and routine lane remain independent; phase/plan builder should not collapse them.</step>
    <step id="S10">Enforce deletion rules: block deleting menus/routines if referenced by a phase/plan; block deleting phases if used by plans (offer duplicate+detach flow). Add request specs for these constraints and user-facing error handling via I18n keys.</step>
    <step id="S11">Update living documentation: `docs/core/SPEC.md` (new REQ IDs for phases + catalogs if needed), `docs/core/SCHEMA_REFERENCE.md`, `docs/core/DATA_FLOW_MAP.md` to reflect new entities and adoption/apply flows. Update `docs/ROADMAP.md` for the post-MVP multi-week menu/routine template extension.</step>
    <step id="S12">Green run: run full RSpec suite; fix any regressions caused by rename and route removal; ensure RuboCop/Reek/ESLint constraints remain satisfied.</step>
  </plan>

  <acceptance_criteria>
    <criterion id="AC1">User can create a Phase with duration N weeks and define menu blocks and routine blocks that fully cover N weeks with no gaps/overlaps; invalid coverage fails with 422 and accessible error reporting.</criterion>
    <criterion id="AC2">User can build a Plan by selecting phases in order; the plan snapshots phases; reordering updates total weeks deterministically; plan is stable unless user explicitly applies updates.</criterion>
    <criterion id="AC3">Public catalogs exist for Plans and Phases (authenticated) with detail pages that show full breakdown; adoption creates one copy per adopter per source; sync shows diff before apply.</criterion>
    <criterion id="AC4">Applying a Plan replaces existing user assignments for menus and routines with a clear warning and user-chosen anchor date (default suggested = today in user TZ).</criterion>
    <criterion id="AC5">Hard constraints enforced: cannot delete menu/routine if referenced; cannot delete phase if used; must duplicate+detach first.</criterion>
    <criterion id="AC6">Rename is complete with CORTE TOTAL: no old `phase_program*` routes, constants, or docs remain; app boots and tests pass.</criterion>
  </acceptance_criteria>
</implementation_plan>

