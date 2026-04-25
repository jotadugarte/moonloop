## Task

- **Roadmap item:** #43 — Registro: peso opcional
- **Primary REQs:** REQ-PROF-001, REQ-WGT-002
- **Goal (draft):** Reducir fricción en registro haciendo el “peso actual” opcional, sin romper BMI/perfil ni el flujo de weight logs.

---

## Current understanding

- Hoy el registro recoge campos de perfil (DOB triplet, timezone, unit system, height) y eso está cubierto por **REQ-AUTH-001** + **REQ-PROF-001** + **REQ-PROF-003** (SPEC).
- **REQ-PROF-002** indica que el usuario almacena `current_weight_kg` y `current_bmi`, con BMI derivado de peso+altura.
- **REQ-WGT-002** define el “weight log entry” como flujo autenticado para registrar pesajes; no implica que el registro deba forzar peso.
- Roadmap #43 pide: en registro, solicitar **peso actual** como **opcional**; si vacío, mostrar en la misma pantalla una indicación clara de que puede añadirlo/actualizarlo luego en perfil.

---

## Key decisions to make (before coding)

1. **Persistencia cuando el peso está en blanco**
   - Opción A: `current_weight_kg = nil` y `current_bmi = nil` (derivado no calculable).
   - Opción B: mantener un valor previo (no aplica en registro).
   - Opción C: guardar 0 (descartado: semánticamente incorrecto).

2. **Validaciones y UX**
   - El campo “peso actual” debe poder enviarse vacío sin 422.
   - Si se provee, debe validarse igual que hoy (rango, formato, unidades según `body_unit_system`).

3. **Interacción con BMI**
   - Con peso ausente, BMI debe quedar vacío / no mostrado donde aplica (y no romper vistas/reportes que asumen presencia).

---

## Scope (proposal)

- **In scope**
  - Registro: campo de peso opcional + copy de “podés completarlo luego”.
  - Reglas servidor: aceptar blank; si blank → no actualizar `current_weight_kg`/`current_bmi`.
  - Re-render 422: mantener visibilidad correcta de inputs (unidad/altura ya resuelto por REQ-PROF-003).
  - I18n: todo copy nuevo por `t(...)`.

- **Out of scope**
  - Cambios de modelo mayor (p.ej. “peso requerido para X”).
  - Cambios al flujo de weight logs (más allá de asegurar que funcione con user sin peso inicial).

---

## Domain model notes

- **Value objects involved (existing):**
  - `BodyMetrics`: parse/format peso según `body_unit_system` (SPEC REQ-PROF-003).
- **Invariants (desired):**
  - Si `current_weight_kg` es `nil`, entonces `current_bmi` debería ser `nil`.
  - Si `current_weight_kg` está presente, `current_bmi` debe estar presente y consistente con altura.

---

## Domain Model

- `WeightKg` (`app/values/weight_kg.rb`)
  - En registro es **opcional**: puede ser `nil`.
  - Cuando está presente, debe ser válido; se deriva/parsea desde inputs UI vía `BodyMetrics`.
- `HeightCm` (`app/values/height_cm.rb`)
  - Requerido por perfil/registro (ya cubierto por REQ-PROF-001).
- `BodyMetrics` (`app/services/body_metrics.rb`)
  - Punto de entrada para parsear/convertir peso/altura según `User#body_unit_system`.
- Invariante de persistencia:
  - `current_weight_kg == nil` ⇒ `current_bmi == nil`.
  - `current_weight_kg` presente ⇒ `current_bmi` derivable desde `HeightCm`.

---

## Open questions (need answers)

## Decisions (confirmed)

1. **Peso opcional aplica a ambos sistemas**: `metric` y `imperial_us`.
2. **Si el peso viene vacío en registro**: persistir `current_weight_kg = nil` y `current_bmi = nil` (no calcular/mostrar BMI donde aplique).
3. **Ubicación del mensaje**: debajo del input de peso.

## Remaining open questions

1. **¿El registro muestra BMI “en vivo”?** Confirmado: **sí**; con peso vacío se oculta / queda vacío (no se calcula).
2. **Copy exacto (i18n)** para el helper debajo del peso (es/en) y si debe incluir link directo a perfil.

---

## Risks / gotchas

- Cualquier lugar que asuma `current_weight_kg` presente puede explotar (helpers, mailers, Informes, perfil).
- Validaciones actuales podrían estar marcando peso como requerido indirectamente (form object/service/model).
- Docs esperados por reglas globales no existen en este repo:
  - `docs/core/i18n_localization_guide.md` (missing)
  - `docs/core/accessibility.md` (missing)
  - Mitigación: seguir las reglas de i18n/a11y descritas en `docs/core/SPEC.md` + `docs/core/SYSTEM_ARCHITECTURE.md` y no hardcodear strings.

# Copy (proposal)

Helper text debajo del input “Peso actual” en registro:

- **es**: “Opcional. Puedes agregarlo o actualizarlo más tarde en tu perfil.”
- **en**: “Optional. You can add it or update it later in your profile.”

Notas:
- Mantenerlo como texto de ayuda asociado al input (para a11y) y **no** como banner.
- Si el producto quiere un link explícito al perfil, definir si será link real (solo aplicable post-registro) o solo texto (recomendado: solo texto en registro).

# Task: Registro — peso opcional (#43)

## Source
- ROADMAP item: **#43** “Registro: peso opcional” (REQ-PROF-001, REQ-WGT-002)

## Goal (draft)
- En la pantalla de registro, solicitar **peso actual** como campo **opcional**.
- Si se deja sin llenar, mostrar en la misma pantalla una indicación clara de que puede **añadirlo o actualizarlo más tarde en el perfil**.

## Open questions
- ¿El “peso opcional” aplica a **ambos sistemas** (`metric` y `imperial`)?
- ¿Qué hacemos si el usuario deja peso vacío pero completa altura/edad? (permitir, sin warnings extra)
- ¿Debe impactar `BMI` en registro si peso es nil? (probable: no calcular hasta tener ambos)
- ¿Qué copy exacto (i18n) debe mostrarse en la pantalla de registro cuando el peso esté vacío?

## Constraints (must follow)
- Docs are source of truth: `docs/core/SPEC.md`, `docs/core/accessibility.md`, `docs/core/i18n_localization_guide.md`.
- No hardcoded user-facing strings (use i18n).
- Turbo invalid form responses use **422** (no redirect for invalid).

## Notes / risks
- A11y: si agregamos helper text, debe estar asociado al input (p. ej. `aria-describedby`) y no duplicar error messaging.
- Data model: permitir `nil` en peso en el flujo de registro sin romper validaciones existentes.

---

<implementation_plan>
  <meta>
    <type>feature</type>
    <roadmap_id>43</roadmap_id>
    <req_ids>
      <req>REQ-PROF-001</req>
      <req>REQ-PROF-002</req>
      <req>REQ-PROF-003</req>
      <req>REQ-WGT-002</req>
      <req>REQ-I18N-001</req>
    </req_ids>
    <notes>
      <note>Auth stack is authentication-zero (see SYSTEM_ARCHITECTURE.md). Do not introduce Devise.</note>
      <note>Controllers must respond with 422 on invalid form submissions (Turbo contract).</note>
    </notes>
  </meta>

  <steps>
    <step>
      <title>Write failing specs for optional weight on registration</title>
      <details>
        <item>Add/extend request spec(s) for registration create: submitting with blank weight succeeds (2xx/redirect as current flow) and persists user with <code>current_weight_kg=nil</code>, <code>current_bmi=nil</code>.</item>
        <item>Spec: when weight is blank, the registration page re-render (422 paths) still shows helper text and does not show BMI (or BMI placeholder is empty/hidden).</item>
        <item>Spec: when weight is present (metric and imperial forms), behavior remains unchanged (weight parsed, BMI computed).</item>
        <item>Tag each example with <code># [REQ-WGT-002]</code> and <code># [REQ-PROF-002]</code> as applicable.</item>
      </details>
    </step>

    <step>
      <title>Locate current registration weight handling and validations</title>
      <details>
        <item>Identify where weight is parsed/assigned during registration (controller/service/form object/model).</item>
        <item>Identify any validation making weight required (directly or indirectly) and adjust to allow blank on create.</item>
      </details>
    </step>

    <step>
      <title>Implement optional weight persistence rules</title>
      <details>
        <item>If submitted weight is blank: persist <code>current_weight_kg=nil</code> and <code>current_bmi=nil</code>.</item>
        <item>If submitted weight is present: keep existing parsing via <code>BodyMetrics</code> (metric vs imperial), compute BMI from weight+height per existing rules.</item>
        <item>Ensure any “reconcile” service or callback does not force BMI when weight is nil.</item>
      </details>
    </step>

    <step>
      <title>Update registration UI copy (i18n) + BMI visibility</title>
      <details>
        <item>Add helper text below the weight field using I18n keys (es/en) as agreed.</item>
        <item>Ensure helper text is associated to the weight input (e.g. <code>aria-describedby</code> if that pattern exists in the app).</item>
        <item>If the registration page shows BMI live: hide or render it empty when weight is blank (server-rendered initial + 422 re-render must match).</item>
      </details>
    </step>

    <step>
      <title>Verify weight log entry flow remains valid for users without initial weight</title>
      <details>
        <item>Add a focused regression spec that a user with <code>current_weight_kg=nil</code> can still create a WeightLog (REQ-WGT-002) and that it reconciles current stats afterward (if that’s the current behavior).</item>
      </details>
    </step>

    <step>
      <title>Documentation touchpoints</title>
      <details>
        <item>Update <code>docs/ROADMAP.md</code> item #43 to done with date when finished.</item>
        <item>If any behavior changes require it, update <code>docs/core/SPEC.md</code> wording for REQ-PROF-002 / REQ-AUTH-001 to clarify weight is optional on registration (only if that’s currently stated as required anywhere).</item>
      </details>
    </step>
  </steps>
</implementation_plan>

