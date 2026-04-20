# ADR-0001: Per-habit reminders — Web Push strategy (browser Push API)

**Status:** Accepted  
**Date:** 2026-04-19

## Context and problem statement

Moonloop is adding **per-habit reminders** with optional **email** and **browser Web Push** channels. We need a boundary decision for how “push” is implemented in this Rails/Hotwire codebase without introducing a mobile push vendor prematurely.

## Decision drivers

- Keep the default stack **Omakase**: Rails + Hotwire + importmap (no mandatory Node bundler).
- Prefer **standards-based Web Push** (browser Push API + service worker) over embedding **FCM** (or other vendor SDKs) inside the Rails app for this product phase.
- Separate **subscription persistence** from **delivery orchestration** so we can ship incrementally with clear security/ops requirements (HTTPS, keys, permission UX).

## Considered options

1. **Browser Web Push (W3C Push API) + VAPID** — store `endpoint` + keys per user/device; server sends HTTP requests to push services.
2. **Firebase Cloud Messaging (FCM) as the primary integration** — vendor SDK/service account management; not required for a web-first MVP.
3. **Pushover/email-only** — external notification vendors; adds cost and UX friction.

## Decision outcome

**Chosen option:** **Browser Web Push (Push API) + VAPID** as the architectural direction for “Web Push” in Moonloop.

**Implementation note:** the application persists **`web_push_subscriptions`** and exposes authenticated subscribe/unsubscribe endpoints (**REQ-HAB-012**). **Sending** on per-habit reminder fire is implemented in **`Habits::DeliverHabitReminderWebPush`**, invoked from **`Habits::ProcessHabitReminderForUserHabit`** after an idempotent **`habit_reminder_events`** insert, using the **`web-push`** gem + VAPID configuration (**`config/initializers/habit_web_push.rb`**) and removing dead subscriptions on **`WebPush::InvalidSubscription`** / **`WebPush::ExpiredSubscription`** (**REQ-HAB-013**). Service worker registration and permission UX remain a **client/browser** concern.

### Positive consequences

- Avoids locking the core product to a mobile-push vendor for a web-first feature.
- Keeps push semantics aligned with how browsers actually deliver notifications.

### Negative consequences

- Operational requirements are non-trivial (HTTPS, key rotation, permission prompts, handling expired endpoints).
- Requires careful testing across browsers and a disciplined approach to user consent.

## More information

- Requirements: **`docs/core/SPEC.md`** (**REQ-HAB-010**–**013**).
- Data mapping: **`docs/core/SCHEMA_REFERENCE.md`** (`web_push_subscriptions`, `habit_reminder_events`).
- Runtime flow: **`docs/core/DATA_FLOW_MAP.md`** (§1.8).
