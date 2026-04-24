## Task
Dataset demo determinista para dev/demo manual (ROADMAP #44).

## Goal
Proveer un set **pequeño**, **rápido** y **reproducible** de datos para usar la app manualmente en desarrollo/demos, cargable vía `db/seeds.rb`, orientado a Postgres.

## Non-Goals (por ahora)
- Catálogo público (public listings).
- Adopción/sync desde catálogo público.

## Key Decisions (locked)
- **Primary use**: dev/demo manual.
- **Mechanism**: `db/seeds.rb`.
- **Determinism**: “random” pero con **seed fijo**.
- **DB**: **solo PostgreSQL**.
- **Users**: **varios perfiles**, variando **timezones** y **métrico vs imperial**.
- **Side effects**: permitidos pero **desactivados por entorno** (no enviar emails/push/jobs en dev seeds).
- **Volume**: set pequeño, con opción futura a dataset grande por flag.

## Minimum Viable Coverage (MVP dataset)
- **Fases + rangos de semanas** con menús y rutinas asignadas.
- **Menús/recetas** (con imágenes default por tipo de comida).
- **Rutinas** (con días de semana y atajos en “Mi Día”).
- **Bundles / PhaseProgram** (aplicar programa completo a un usuario).
- **Hábitos**:
  - ejemplos con `habit_metric_kind` + `daily_target` (REQ-DAY-005),
  - completions que produzcan **streaks** visibles.
- **Peso**:
  - historial suficiente para gráficos e informes,
  - cubrir **métrico e imperial**,
  - coherente con reconciliación de “current stats” (último `logged_at` manda).

## Data Shape (expectativas)
- Crear 2–4 usuarios demo:
  - al menos 1 con timezone América (p.ej. `America/Mexico_City`) y otro Europa (p.ej. `Europe/Madrid`)
  - al menos 1 en sistema **imperial** y otro **métrico**
- Para cada usuario:
  - hábitos activos con mezcla de targets (ej. agua con target, ejercicio booleano, etc.)
  - completions de “ayer/hoy” calculadas en **zona horaria del usuario**
  - 8–20 weight logs con `logged_at` espaciado (semanal/bi-semanal), coherentes con BMI/altura snapshot
  - plan de fases + menú + rutina “vigente” hoy
  - al menos 1 bundle (PhaseProgram) aplicable y aplicado a 1 usuario

## Edge Cases / Dark Corners (must handle)
- **Timezones**:
  - generación de completions debe usar “hoy/ayer” según el **día local** del usuario (no UTC).
  - evitar flakiness por `Time.zone` global; usar zona del usuario al crear timestamps/dates.
- **Idempotencia**:
  - `db:seed` no debe duplicar todo en cada corrida.
  - definir estrategia: upsert por “claves naturales” (email, nombres únicos por user) o wipe controlado solo en dev.
- **Side effects**:
  - evitar disparar envíos de recordatorios, emails o Web Push por seeds.
  - evitar scheduling/recurring jobs por seeds (o asegurar que no corren en dev).
- **Weight/BMI**:
  - garantizar que el “último” `logged_at` quede como current stats post-seed.
  - cubrir conversiones imperial/métrico sin inconsistencias.
- **Performance**:
  - dataset pequeño por defecto; todo en segundos.
  - permitir un flag futuro para dataset grande (sin que sea el default).

## Common Mistakes to Avoid
- Semillas no deterministas (cambian cada corrida sin poder reproducir).
- Duplicación de rows por falta de idempotencia.
- Completions que caen en el “día equivocado” por timezone.
- Semillas que accidentalmente disparan emails/push/jobs.
- Datos “bonitos” pero que no muestran nada en pantallas clave (Mi Día / Informes / Phase).

## Open Questions (to resolve)
- Estrategia exacta de idempotencia a adoptar en seeds:
  - ✅ A) **Upsert** por email/nombre (preferible para no borrar datos ajenos)
- Lista exacta de timezones + perfiles a usar:
  - ✅ 3 perfiles demo (ver Implementation Plan: perfiles propuestos)

## Acceptance Criteria
- Ejecutar `db:seed` en Postgres deja un set pequeño de usuarios demo y datos navegables.
- “Mi Día” muestra hábitos y una rutina/menú activo consistente para al menos 2 perfiles.
- “Informes” tiene datos (streaks + peso chart) para al menos 2 perfiles.
- Re-ejecutar `db:seed` **no duplica** datos demo (idempotente).
- No se envían emails/push ni se programan jobs por el acto de seed en dev.

## Next
Preparar `<implementation_plan>` con pasos concretos para implementar el seed en `db/seeds.rb` sin romper arquitectura ni efectos secundarios.

<implementation_plan>
  <meta>
    <roadmap_item_id>44</roadmap_item_id>
    <name>Dataset demo determinista (dev/demo)</name>
    <primary_entrypoint>db/seeds.rb</primary_entrypoint>
    <db>postgresql</db>
  </meta>

  <principles>
    <principle>Determinismo: fijar seed RNG (p.ej. Random.new(1234)) y no depender de Time.now sin control de zona.</principle>
    <principle>Idempotencia: upsert por claves naturales (email de demo, nombres estables por user, etc.).</principle>
    <principle>Sin efectos secundarios: durante seeds, desactivar envíos (mail/push) y evitar encolar jobs.</principle>
    <principle>Pequeño por defecto: dataset en segundos; permitir flag futuro para dataset grande.</principle>
  </principles>

  <dataset>
    <demo_profiles>
      <profile id="u1">
        <email>demo+mx-metric@moonloop.local</email>
        <timezone>America/Mexico_City</timezone>
        <body_unit_system>metric</body_unit_system>
      </profile>
      <profile id="u2">
        <email>demo+es-imperial@moonloop.local</email>
        <timezone>Europe/Madrid</timezone>
        <body_unit_system>imperial</body_unit_system>
      </profile>
      <profile id="u3">
        <email>demo+us-metric@moonloop.local</email>
        <timezone>America/Los_Angeles</timezone>
        <body_unit_system>metric</body_unit_system>
      </profile>
    </demo_profiles>

    <coverage>
      <menus_and_phases>Crear plan de fases (start date) y asignaciones de menús por rangos de semanas; asegurar “vigente hoy”.</menus_and_phases>
      <recipes>Crear algunas recetas por meal type; dejar que la app resuelva “default image” donde aplique.</recipes>
      <exercise_routines>Crear rutina con asignación por día de semana; asegurar que Mi Día la muestre vinculada a hábito Ejercicio.</exercise_routines>
      <phase_program_bundle>Crear al menos 1 PhaseProgram con segmentos menú+rutina por rango de semanas y aplicarlo a 1 perfil.</phase_program_bundle>
      <habits_metrics_and_streaks>Definir hábitos con métricas/targets (REQ-DAY-005) y crear completions (ayer/hoy) en día local para generar streaks.</habits_metrics_and_streaks>
      <weight_logs>Crear historial (8–12 logs) con logged_at en zona del usuario y coherente con BMI/altura snapshot; reconciliar current stats al final.</weight_logs>
    </coverage>
  </dataset>

  <steps>
    <step>Inventariar modelos/servicios existentes a reutilizar desde seeds (p.ej. servicios de apply bundle, upsert de menús, logging de peso) y confirmar APIs públicas estables.</step>
    <step>Definir helpers internos en `db/seeds.rb` (o `db/seeds/*` requerido por seeds.rb si el repo ya usa esa convención) para: RNG determinista, “local today” por usuario, y upsert por email.</step>
    <step>Implementar creación/upsert de 3 usuarios demo con perfiles: timezone, métricas corporales (altura/peso inicial), sistema métrico/imperial.</step>
    <step>Para cada usuario: asegurar hábitos base y configurar al menos 2 hábitos con target (REQ-DAY-005) y 1 hábito booleano; activar lo necesario para que Mi Día muestre contenido.</step>
    <step>Crear completions “ayer/hoy” usando día local del usuario para evitar inconsistencias por UTC; validar que streaks resultan visibles.</step>
    <step>Crear 8–12 weight logs por usuario con timestamps espaciados; al final ejecutar (o emular) reconciliación de stats para que current weight/BMI refleje el último log.</step>
    <step>Crear menús/recetas mínimos y un plan de fases que los asigne por rangos; asegurar que hoy caiga dentro de un rango asignado.</step>
    <step>Crear rutinas y asignarlas por rangos de semanas; asegurar que el “hábito Ejercicio” en Mi Día enlace a la rutina activa.</step>
    <step>Crear 1 PhaseProgram bundle y aplicarlo a 1 usuario; confirmar que el plan resultante es navegable.</step>
    <step>Blindar side-effects durante seed: envolver el seed en un “guard” de entorno (dev) y deshabilitar delivery/enqueue donde corresponda (sin modificar producción).</step>
    <step>Verificar idempotencia: re-ejecutar `db:seed` y confirmar que no duplica; ajustar claves naturales y upserts hasta pasar.</step>
  </steps>

  <verification>
    <manual_checks>
      <check>Re-correr `db:seed` y confirmar conteos estables (sin duplicados) para usuarios demo y entidades asociadas.</check>
      <check>Con cada demo user: abrir “Mi Día” y ver hábitos + rutina/menú vigente; completar algo y ver feedback.</check>
      <check>Abrir “Informes” y confirmar que aparecen streaks y chart de peso con series no vacías.</check>
      <check>Confirmar que no se enviaron emails ni Web Push ni se encolaron jobs por seeds (en dev).</check>
    </manual_checks>
  </verification>
</implementation_plan>
