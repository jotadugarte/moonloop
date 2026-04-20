# Task: Recordatorios — entrega email + Web Push (REQ-HAB-013)

## Metadata

| Campo | Valor |
|--------|--------|
| **Tipo** | Feature (cierre de circuito sobre MVP existente) |
| **Origen** | `docs/ROADMAP.md` — *pendiente:* orquestar envío email/push desde processor/job; `docs/core/SPEC.md` **REQ-HAB-013** (Planned); **ADR-0001** (envío explícitamente follow-up). |
| **Contexto previo** | Sesión archivada `.agenticguild/completed_sessions/task_habit-reminders_2026-04-19.md` (prefs, sweep, `habit_reminder_events`, suscripciones, mailer sin cablear). |
| **Código ancla** | `Habits::ProcessHabitReminderForUserHabit` hoy crea `HabitReminderEvent` y no despacha canales. Paridad deseada con `Phases::ProcessPhaseStartReminderForUser` (evento idempotente primero, luego correo). |

## Decision log

| Fecha | Decisión |
|--------|-----------|
| 2026-04-19 | **Nueva sesión activa** `task_habit-reminders-delivery.md`: alcance confirmado por producto — cablear **email** y **Web Push** cuando el processor gana la carrera idempotente (`HabitReminderEvent` insertado, no `RecordNotUnique`). |
| 2026-04-19 | **Orden de efectos:** solo despachar canales **después** de `create!` exitoso del evento; en `RecordNotUnique` no reenviar (mismo día ya procesado). |
| 2026-04-19 | **Email:** usar **`deliver_now`** tras el insert exitoso, en línea con `PhaseStartReminderMailer` y specs que miden `ActionMailer::Base.deliveries` (evita ambigüedad de cola en tests sin perfilar `deliver_later`). |
| 2026-04-19 | **Web Push:** estándar **VAPID** + gem **`web-push`** (o equivalente mantenido) para cifrado/payload; claves en **Rails credentials**; suscripciones inválidas (**HTTP 404/410** u errores de “gone”) → **eliminar** fila `web_push_subscriptions` para no reintentar en vano. |
| 2026-04-19 | **Payload:** título/cuerpo mínimos con **I18n** (`es`/`en`), coherentes con el mailer (nombre del hábito); sin FCM en app. |
| 2026-04-19 | **Domain Model (Phase 3.0):** tipos y responsabilidades del bloque *Domain Model (CbC)* **aprobados** por el usuario; sin cambios de nombres ni invariantes. |

## Domain Model (CbC)

### Reminder channel dispatch (efímero, no tabla nueva obligatoria)

- **Responsabilidad:** materializar el envío real por canal una vez que el **día local** quedó registrado en `habit_reminder_events`.
- **Invariantes:**
  - No enviar email si `user_habit.reminder_email` es false; no enviar push si `reminder_web_push` es false.
  - No ejecutar envíos si no hubo insert exitoso del evento (incl. dedupe por unicidad).
  - Push: iterar **todas** las `web_push_subscriptions` del `user`; fallos por suscripción muerta no deben impedir intentar el resto (best-effort por dispositivo).
- **Value objects / tipos:**
  - **`VapidConfig`** — `public_key`, `private_key`, `subject` (mailto: o URL) leídos de configuración/credentials; fallo claro en boot o en primer envío si faltan en producción.
  - **`WebPushNotificationPayload`** — `title`, `body`, `tag` opcional (dedupe en cliente), serializable a JSON UTF-8 para el cuerpo cifrado.

### `WebPushSubscription` (existente)

- **Invariantes:** tras envío, si el endpoint rechaza con “gone”/not found, la fila se borra; integridad `(user_id, endpoint)` se mantiene.

## Riesgos y notas

- **Jobs:** el sweep ya invoca el processor; `deliver_now` acumula latencia SMTP en el mismo job — aceptado por paridad con fase; si en prod molesta, ADR o tuning posterior a `deliver_later`.
- **VAPID en CI/test:** usar claves de prueba en credentials de test o stub del cliente Web Push en specs unitarios; un spec de integración opcional con mock HTTP.
- **REQ status:** no marcar **REQ-HAB-013** como Implemented en `SPEC.md` hasta que el processor despache al menos el email y el push esté implementado y cubierto por specs (criterio “end-to-end wiring” del `SYSTEM_ARCHITECTURE.md`).
- **Documentación:** actualizar **ADR-0001** (nota de implementación), **DATA_FLOW_MAP** §1.8, **ROADMAP** línea In Progress, **CHANGELOG** si aplica.

---

**Estado:** plan de implementación listo para `start-task` (validado: Feature con pasos test-first).

<implementation_plan>
  <classification>Feature</classification>
  <mandate>
    TDD estricto: no introducir lógica de producción nueva sin un ejemplo RSpec que haya fallado primero para ese comportamiento.
    Respetar `docs/core/SYSTEM_ARCHITECTURE.md`: servicios bajo `app/services/`, I18n sin strings hardcodeados en vistas/mailers/payloads, Hotwire/importmap sin bundler nuevo.
    Mantener idempotencia actual: despacho solo tras `HabitReminderEvent.create!` exitoso; ningún envío en ruta `ActiveRecord::RecordNotUnique`.
  </mandate>

  <step id="1" status="complete">Escribir **fallando** ejemplos en `spec/services/habits/process_habit_reminder_for_user_habit_spec.rb`: cuando el processor crea el evento y `reminder_email` es true, debe incrementarse `ActionMailer::Base.deliveries` en exactamente 1 y el correo debe ser `HabitReminderMailer#notify` con `user` y `user_habit` esperados (mismo estilo que `ProcessPhaseStartReminderForUser`). Incluir caso `reminder_email: false` sin entregas.</step>

  <step id="2" status="complete">Implementar en `Habits::ProcessHabitReminderForUserHabit` la llamada a `HabitReminderMailer.notify(user:, user_habit:).deliver_now` **solo** tras `create!` exitoso y si `user_habit.reminder_email?`. Mantener el `rescue RecordNotUnique` sin envíos. Verificar specs en verde.</step>

  <step id="3" status="complete">Escribir **fallando** ejemplo de idempotencia de email: dos invocaciones el mismo día local solo producen **un** correo (misma línea base que evento único). Ajustar implementación si hiciera falta hasta verde.</step>

  <step id="4" status="complete">Añadir dependencia **`web-push`** al Gemfile (versión acotada), `bundle install`, y documentar en el plan de credenciales las claves VAPID (sin commitear secretos). Escribir **fallando** specs para un servicio nuevo, p. ej. `Habits::DeliverHabitReminderWebPush`, que: con `user_habit` y `user` con suscripciones, invoca el cliente de envío una vez por suscripción; con lista vacía no levanta error; ante error simulado de suscripción inválida elimina esa fila. Usar stubs/doubles en unit tests para no llamar la red.</step>

  <step id="5" status="complete">Implementar `Habits::DeliverHabitReminderWebPush` hasta verde: construir payload I18n (título/cuerpo con nombre de hábito), leer `VapidConfig` desde Rails application config alimentada por credentials, manejar respuestas 404/410 (u excepciones documentadas por la gem) con `destroy` de la suscripción afectada.</step>

  <step id="6" status="pending">Escribir **fallando** spec de integración en el processor: con `reminder_web_push: true`, suscripción de fábrica y cliente Web Push stubbeado, tras procesar se intenta envío; con `reminder_web_push: false` no se llama al servicio de push. Integrar la llamada al servicio en `Habits::ProcessHabitReminderForUserHabit` tras insert exitoso del evento.</step>

  <step id="7">Actualizar documentación: `docs/core/SPEC.md` (**REQ-HAB-013** a Implemented con criterios de wiring), `docs/core/ADRs/0001-habit-reminders-web-push.md` (nota de que el envío en reminder está implementado), `docs/core/DATA_FLOW_MAP.md` §1.8, `docs/ROADMAP.md` (cerrar o acotar ítem In Progress), `CHANGELOG.md` si el repo lo usa para releases. Añadir/ajustar comentarios `# [REQ-HAB-013]` en archivos tocados según `.cursor/rules/spec-req-traceability.mdc`.</step>

  <step id="8">Pase final: `bundle exec rspec` (o equivalente del proyecto) en verde; revisar que no se dupliquen envíos bajo reentrada del job y que sigan cumpliéndose **REQ-HAB-010**–**012**.</step>
</implementation_plan>
