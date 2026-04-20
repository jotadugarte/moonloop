# Task: Recordatorios por hábito (email + push)

## Metadata

| Campo | Valor |
|--------|--------|
| **Tipo** | Feature |
| **Origen** | `docs/ROADMAP.md` — Backlog: *Push notifications and/or per-habit email reminders* (distinto de recordatorios de inicio de fase — **Done #18**, REQ-MENU-004 / REQ-EXR-004). |
| **Canales** | **Email** y **Web Push** en la misma entrega (prioridad acordada con producto). |
| **REQ** | Pendiente registrar en `docs/core/SPEC.md` (nuevos `REQ-*` para preferencias por hábito, canales, idempotencia y push); alinear con trazabilidad `# [REQ-…]`. |
| **Arquitectura** | `docs/core/SYSTEM_ARCHITECTURE.md`: servicios bajo `app/services/`, Active Job + Solid Queue, I18n `es`/`en`, Hotwire; **sin** FCM en app hoy — Web Push estándar implica service worker + suscripciones + claves VAPID (decisión de infra a documentar). |

## Decision log

| Fecha | Decisión |
|--------|-----------|
| 2026-04-19 | **Nueva sesión** de explore / implementación: puntero activo movido desde `task_imperial-units.md` (cerrado) a este archivo. |
| 2026-04-19 | **Alcance de canales:** entregar **ambos** — email y push — en la misma feature (pueden activarse por separado por hábito o con defaults de usuario; detalle en diseño de UI/prefs). |
| 2026-04-19 | **Modelo de tiempo (MVP recomendado):** **una hora local fija por hábito** interpretada en **`User#timezone`** (mismo patrón mental que “Mi Día” y recordatorios de fase por día local). Motivos: predecible para el usuario, encaja con **job recurrente** que barre “ventanas” o minutos (paridad con `Phases::SweepPhaseStartRemindersJob` + idempotencia por día), y simplifica tests y SPEC. |
| 2026-04-19 | **Diferido (fase 2 producto):** recordatorios **condicionales** (“solo si no completado antes de X”) o ventanas vagas (“en la mañana”) — más lecturas de `HabitCompletion` / reglas de “due” y más edge cases; no bloquea el diseño base si el esquema guarda hora + flags de canal. |
| 2026-04-19 | **Confirmación producto:** **una hora local fija por hábito** (un solo toque al día en MVP); sin múltiples horarios por hábito hasta una fase posterior. |
| 2026-04-19 | **Regla de envío (MVP):** si el hábito ya está **cumplido para ese día local** antes de la hora programada, **no enviar** email ni push ese día (evita ruido; el job consulta el mismo criterio de “done” que Mi Día / rachas). |
| 2026-04-19 | **Defaults en creación de hábito:** recordatorio **apagado** por defecto; el usuario lo habilita explícitamente desde la pantalla de creación/edición. |
| 2026-04-19 | **Canales en MVP:** **solo email + Web Push** (sin in-app banner/toast en esta entrega). |

## Patrón existente a reutilizar (fase / correo)

- Recordatorios de inicio de fase: `Phases::SweepPhaseStartRemindersJob` → `Phases::ProcessPhaseStartReminderForUser` → `PhaseReminderEvent` (unicidad `(user_id, kind, local_date)`) + mail condicionado a `User#phase_reminder_email?` e in-app con `phase_reminder_in_app?`.
- **Paridad deseable:** bookkeeping idempotente por **día local** (y hábito) para no duplicar emails ni pushes; preferencias de canal **independientes** donde tenga sentido (email vs push vs in-app).

## Domain Model (aprobado — CbC)

### Habit reminder configuration (por hábito)

- **Responsabilidad:** definir si un `UserHabit` tiene recordatorio, a **qué hora local** dispara (MVP: un instante o `time-of-day` + timezone del usuario al calcular), y qué canales están activos.
- **Invariantes:**
  - Solo hábitos **activos** elegibles para recordatorio (alineado a reglas de hábitos desactivados).
  - La hora se interpreta siempre en la zona del **usuario** (`timezone` presente y válida para scheduling).
- **Value objects / tipos (aprobado):**
  - **`LocalTimeOfDay`** — hora + minuto (sin fecha) para UI y persistencia neutral; conversión a `Time` del día solo con `ActiveSupport::TimeZone` del usuario.
  - **`ReminderChannelSet`** — conjunto cerrado de canales (`email`, `web_push`) con regla “si el recordatorio está habilitado, debe existir al menos un canal”.
  - **`HabitReminderDedupeKey`** — clave lógica de idempotencia por `(user_id, user_habit_id, local_date)` para dedupe por **día local**.

### HabitReminderEvent (nombre tentativo)

- **Responsabilidad:** registro idempotente de “ya enviamos el recordatorio lógico para este hábito en este día local” (y quizá `kind` si hay variantes futuras).
- **Invariantes:** una fila como máximo por clave única acordada; no implica que el push haya sido entregado (solo que el job intentó / encoló).

### Web Push subscription

- **Responsabilidad:** almacenar endpoint y claves del navegador para el usuario (posiblemente varios dispositivos).
- **Invariantes:** datos mínimos para Web Push; revocación limpia al logout o “desuscribir”; no mezclar con tokens FCM hasta ADR.

### User (extensión opcional)

- Mantener el diseño centrado en `UserHabit` (prefs por hábito). Defaults globales a nivel usuario quedan fuera del MVP salvo necesidad de UX.

## Riesgos y notas

- **Web Push:** requiere HTTPS en producción, service worker, permisos del navegador, rotación VAPID; mayor superficie que Action Mailer solo.
- **DST:** usar siempre `User#timezone` y APIs que respeten cambios de horario al mapear “hora del día” a instante UTC en el job.
- **Solid Queue:** volumen de sweep — si hay muchos usuarios/hábitos, puede hacer falta particionar por ventana de minutos o índices en prefs; perfilar después del MVP.
- **No confundir** con REQ-MENU-004 (fase): copy, mailers y prefs son dominios distintos aunque el motor de jobs sea similar.

## Preguntas abiertas

*(Ninguna bloqueante: alcance y reglas MVP confirmadas.)*

---

**Estado:** **SPEC LISTO** — a continuación se incluye el plan normativo para ejecutar con `start-task` (TDD estricto).

<implementation_plan>
  <classification>Feature</classification>
  <mandate>
    TDD: no implementar lógica de producción sin un ejemplo RSpec que haya fallado primero para ese comportamiento.
    Mantener `docs/core/SYSTEM_ARCHITECTURE.md`: servicios bajo `app/services/`, Active Job + Solid Queue, I18n; sin strings hardcodeadas.
    Mantener paridad conceptual con recordatorios de fase: sweep recurrente + evento idempotente por día local.
  </mandate>

  <step id="1" status="complete">Escribir **fallando** specs de modelo/servicio para el **modelo de configuración por hábito**: persistir (en `UserHabit` o tabla nueva) `reminder_enabled=false` por defecto, `reminder_time_of_day` (hora+minuto), y flags de canal (email/push) solo aplicables cuando está habilitado. Cubrir validaciones mínimas y que un hábito desactivado no sea elegible.</step>

  <step id="2" status="complete">Implementar migraciones/modelos hasta **verde** (incluyendo índices que ayuden al sweep por hora/minuto si aplica). Mantener el diseño centrado en prefs por hábito; no introducir defaults globales en `User` salvo necesidad de UI.</step>

  <step id="3" status="complete">Escribir **fallando** specs para **idempotencia**: crear entidad tipo `HabitReminderEvent` con unicidad por `(user_id, user_habit_id, local_date)` (y canal/kind solo si se justifica). Confirmar que ante reintentos o ejecución repetida no duplica envíos lógicos.</step>

  <step id="4" status="pending">Implementar `HabitReminderEvent` y su uso hasta **verde**.</step>

  <step id="5" status="pending">Escribir **fallando** specs para el **sweep job recurrente** (Solid Queue + `config/recurring.yml`): para cada usuario con `timezone` válida, calcular el “slot” de hora local actual, seleccionar hábitos con recordatorio habilitado en ese slot y **activos**, y encolar/procesar envíos por email y push según flags de canal. Asegurar que el sweep usa el día **local** para dedupe.</step>

  <step id="6" status="pending">Implementar el job y el servicio orquestador (p. ej. `Habits::SweepHabitRemindersJob` + `Habits::ProcessHabitReminderForUserHabit`) hasta **verde**. Seguir el patrón existente de `Phases::ProcessPhaseStartReminderForUser` (incluyendo rescue de `RecordNotUnique`).</step>

  <step id="7" status="pending">Escribir **fallando** specs para la regla MVP “**no enviar si ya cumplido**”: si el `UserHabit` está marcado como **done** para ese `local_date` antes de la hora programada, no crear evento ni enviar (email/push). Usar el mismo criterio de “done” que Mi Día/rachas (servicio existente a localizar y reutilizar).</step>

  <step id="8" status="pending">Implementar la consulta de “done para día local” hasta **verde**, evitando N+1. Documentar en `docs/core/DATA_FLOW_MAP.md` si introduce nuevas lecturas/caches.</step>

  <step id="9" status="pending">Email: escribir **fallando** specs para el mailer de recordatorio por hábito (I18n `es`/`en`, subject y cuerpo con nombre de hábito/categoría). Implementar mailer/vistas hasta **verde**.</step>

  <step id="10" status="pending">Web Push: escribir **fallando** specs para el flujo de **suscripción** (guardar endpoint + p256dh + auth por usuario, permitir múltiples dispositivos) y para el servicio de envío. Implementar service worker/JS mínimo bajo importmap/stimulus (sin Node), endpoints de subscribe/unsubscribe, y servicio de envío Web Push con claves VAPID configurables. Mantenerlo apagado por defecto hasta que el usuario conceda permiso en el navegador.</step>

  <step id="11" status="pending">UI en creación/edición de hábito: escribir **fallando** system/request specs que verifiquen que el recordatorio aparece en el formulario, por defecto apagado, y al habilitarlo permite escoger hora local y canales (email/push) y persiste. Implementar vistas y strong params hasta **verde** (sin in-app banners).</step>

  <step id="12" status="pending">Actualizar `docs/core/SPEC.md` con nuevos `REQ-*` (config por hábito, sweep + idempotencia, email, Web Push) y añadir trazabilidad `# [REQ-…]` en archivos tocados según `.cursor/rules/spec-req-traceability.mdc`. Actualizar `docs/core/SCHEMA_REFERENCE.md` si se agregan tablas/columnas nuevas.</step>

  <step id="13" status="pending">Pase final: suite completa en verde; revisar que no se mezcló con recordatorios de fase; preparar para `finish-branch` cuando corresponda.</step>
</implementation_plan>
