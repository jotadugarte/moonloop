<task_session>
  <metadata>
    <task_name>Programas de Fases Unificadas (Bundles)</task_name>
    <type>Feature</type>
    <req_id>REQ-PHS-001 (registry + criteria to be added in SPEC in plan step 1)</req_id>
    <roadmap_item>#33 — Programas de Fases Unificadas (Bundles); depends on Done #30, #31, Phase 4 #17</roadmap_item>
  </metadata>

  <implementation_plan>
    <step id="1" status="pending">Add **REQ-PHS-001** (and `PHS` domain row) plus glossary + acceptance bullets in `docs/core/SPEC.md`, aligned with `docs/ROADMAP.md` #33 and parity with **REQ-MENU-006** / **REQ-EXR-006** (catalog, adoption, fingerprint, unavailable source, admin revoke). Update `docs/core/SCHEMA_REFERENCE.md` when tables are introduced. **Test first:** write a failing model spec `spec/models/phase_program_spec.rb` tagged `# [REQ-PHS-001]` expecting the `PhaseProgram` constant and persisted attributes (`user`, `name`, optional `publicly_shareable`, adoption source columns mirroring menus/routines). **Implement:** migration + `PhaseProgram` model with validations (non-blank name, user required) and `belongs_to :user` until the spec is green.</step>
    <step id="2" status="pending">Define how a program binds **menu** and **routine** week plans: introduce join model(s) (e.g. `phase_program_assignments` mapping `start_week..end_week` → `menu_id` + `exercise_routine_id`, scoped to `user_id` / program, non-overlapping week ranges **within the same bundle**). **Pre-conditions / post-conditions:** ranges satisfy same DB checks as `phase_assignments` / `exercise_routine_assignments`; destroying a program does not orphan the user’s standalone menus/routines unexpectedly (decide: restrict destroy if materialized, or cascade policy — document in SPEC). **Test first:** model specs for overlap validation and happy-path two-segment program. **Implement:** migration + associations from `PhaseProgram` + `User`.</step>
    <step id="3" status="pending">Service **`Programs::ApplyBundleToUser`** (name aligned with repo conventions under `app/services/programs/` or agreed namespace): given a `PhaseProgram` owned by the user, materialize or replace the user’s **`PhaseAssignment`** and **`ExerciseRoutineAssignment`** rows so week indices resolve menus+routines together (single writer; transaction). **Pre-conditions:** program segments cover intended weeks without conflicting with existing user rows **or** define explicit merge/replace policy in SPEC. **Test first:** service spec with factories for menus/routines/program segments; assert resulting `phase_assignments` / `exercise_routine_assignments` rows. **Implement:** service + small orchestration from existing `Phases::*` validation ideas (no fat controller).</step>
    <step id="4" status="pending">Authoring UI: index/create/edit/destroy for the owner’s programs and segment editor (Turbo-friendly forms, I18n). **Test first:** request or system spec covering create program, add two week ranges with chosen menu + routine, submit apply action. **Implement:** routes, controller, ERB views, flashes; reuse patterns from menus / exercise routines / phase plan screens.</step>
    <step id="5" status="pending">Public catalog: `publicly_shareable` programs, authenticated index/show, opt-in toggle for owner, admin revoke parity (**REQ-PHS-001**). **Test first:** request specs for index (only public), revoke path if applicable. **Implement:** `PublicPhaseProgramsController` (or agreed name), policies consistent with `PublicMenusController` / `PublicExerciseRoutinesController`.</step>
    <step id="6" status="pending">**Adopción integral:** service `Programs::AdoptFromPublicCatalog` — duplicate nested menus and routines (recipes via existing `Menus::DuplicateRecipeForAdopter`, routine lines/bodies via existing exercise duplication helpers), set `source_*` + fingerprint fields, single transaction; block adopt-own, duplicate adopt per source, name stable on sync (mirror **#31** / **#30** semantics). **Test first:** service spec with public template program + adopter; assert copied menu/routine ownership and entries. **Implement:** adoption service + controller action + I18n errors.</step>
    <step id="7" status="pending">**Drift + sync:** `Programs::AdoptionSyncStatus`, `Programs::ApplyAdoptionSourceSync` mirroring menus/routines (fingerprint compare, unavailable source, retry when origin changed). **Test first:** specs for pending/synced/unavailable. **Implement:** services + UI affordance on edit screen.</step>
    <step id="8" status="pending">Integrate entry points: link from **`/phase`** (phase plan) to “programas” where product expects a single coordinated bundle vs independent menu/routine editors; ensure Mi Día / phase week resolution still uses existing `Phases::WeekNumber` + assignments (no duplicate week math). **Test first:** request or system spec proving navigation + that active week still resolves correct menu/routine after apply. **Implement:** minimal Turbo links/copy; adjust `docs/core/DATA_FLOW_MAP.md` if behavior crosses entities.</step>
  </implementation_plan>

  ## Domain Model

  **Aprobado:** 2026-04-19.

  - **`Programs::ProgramName`** — Value object sobre el nombre visible: `strip`, no vacío, longitud máxima alineada con las reglas de nombre de `Menu` / `ExerciseRoutine` y normalización coherente con el resto de la app.
  - **`Programs::WeekIndexRange`** — Par inmutable `start_week`, `end_week` con invariantes de `PhaseAssignment` / `ExerciseRoutineAssignment` (`start_week >= 1`, `end_week >= start_week`).
  - **`Programs::BundleContentFingerprint`** — Envoltorio del fingerprint en string para deriva catálogo / adopción; cálculo vía colaborador pequeño, en paridad explícita con fingerprints de menús y rutinas.
  - **Persistencia (ActiveRecord):** `PhaseProgram`, modelo(s) de filas por rango de semanas hacia `Menu` y `ExerciseRoutine` (nombre de tabla final en migración); claves foráneas y pertenencia a `User`. IDs numéricos en rutas/controladores salvo decisión posterior de slug.

  <working_notes>
    Nombre de modelo **`PhaseProgram`** es convención de trabajo; confirmar o renombrar en **Step 3.0 (Domain Model)** del skill antes de escribir tests de dominio definitivos.
  </working_notes>
</task_session>
