# ADR-0003: Return 422 Instead of Redirect+Flash for Invalid Form Submissions (Turbo)

**Date:** 2026-04-22
**Status:** Accepted
**Branch:** views
**Related requirements:** REQ-DAY-002, REQ-PROF-001

---

## Context

Moonloop uses Hotwire (Turbo) for form submissions. When a form submission fails
validation or encounters a domain error, the server must signal the failure in a
way that Turbo understands.

Before this decision, some controllers responded to invalid input with
`redirect_to path, alert: t("...")`. While this works for classic browser
navigation, it is incorrect for Turbo Drive: Turbo treats any 2xx or 3xx
response to a form submission as a successful navigation and **replaces** the
page — discarding the form state and preventing inline error display.

The Rails + Turbo convention for "validation failed" is to re-render the form
with a **422 Unprocessable Content** status. Turbo intercepts the 422 and keeps
the current page, allowing the re-rendered form (with error messages) to appear
in place.

## Decision

Controllers that handle form submissions **must** respond with
`head :unprocessable_content` (or `render ..., status: :unprocessable_content`)
when the submission is invalid, cannot be processed, or the requested resource
does not belong to the current user (preventing silent redirect loops).

Specifically:

- `HabitCompletionsController#create` — rescue paths for
  `ActionController::ParameterMissing`, `ArgumentError`, `TypeError`, and
  unknown `user_habit_id` → `head :unprocessable_content`.
- `ProfilesController` (and any future form controller) — validation failure on
  `update` → render the form with `status: :unprocessable_content`.

Flash-based redirects are retained only for **successful** submissions and for
**domain-level** business rule rejections that intentionally navigate away
(e.g. future-date protection, inactive-habit protection), where the redirect
itself is the intended UX.

## Consequences

- **Turbo compatibility:** Turbo correctly intercepts 422 responses, preserving
  form state and enabling inline error display without a full page reload.
- **Test coverage:** HTTP status assertions for error paths belong in
  **request specs** (`spec/requests/`), not system specs using
  `page.driver.post` (which only works with the `rack_test` driver).
- **Flash messages lost on 422 `head`:** `head :unprocessable_content` sends no
  body, so flash messages are not rendered. This is acceptable for the current
  error paths (invalid parameter structure, unknown habit ID) because the
  calling context is a Turbo form that will re-render the frame on 422. Any path
  where the user requires visible feedback on a 422 must render a full response
  (not `head`), including an error container with `role="alert"`.

## Alternatives considered

- **Keep redirect+flash:** Rejected. Turbo Drive treats 3xx as success and
  discards the form error state. The user sees no inline feedback.
- **Turbo Stream error response:** Valid future enhancement for richer UX
  (e.g. appending an error banner via stream). Not adopted in this iteration;
  `head :unprocessable_content` is the minimal correct signal for Turbo.
