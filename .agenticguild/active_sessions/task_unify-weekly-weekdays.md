% Task: unify-weekly-weekdays
% Roadmap: #10 — Unificar `weekly` en `weekdays`, migrar datos y alinear SPEC (REQ-HAB-005).

---

## Session metadata

- **Roadmap item:** #10 (Phase 3 — prerequisite for Mi Día scheduling)
- **Classification:** Refactor (schema semantics + data migration + spec alignment)
- **REQ traceability:** REQ-HAB-005; glossary row for frequency types in `docs/core/SPEC.md`

---

## Scope note

Replaces the broader `task_phase-3-mi-dia.md` plan for **this active pointer** only while this task runs. After #10 ships, you may resume Phase 3 Mi Día from that session file or merge plans as needed.

---

<implementation_plan>
  <roadmap_item>10</roadmap_item>
  <classification>Refactor</classification>
  <description>Remove `weekly` as a `user_habits.frequency_type`. Represent “once per week on day D” exclusively as `weekdays` with `frequency_params["weekdays"]` containing one or more integers 0–6 (single element = weekly cadence). Add a defensive data migration for any existing `weekly` rows; update `UserHabit` validations; align `docs/core/SPEC.md` (glossary + REQ-HAB-005) per `.cursor/rules/spec-md-req-registry.mdc`; sweep templates, seeds, factories, and UI copy that referenced habit `weekly` type.</description>

  <step id="1" status="complete">Run `bundle exec rspec` to establish a green baseline on the branch; do not change application code in this step.</step>

  <step id="2" status="complete">Write a failing model spec: a `UserHabit` with `frequency_type: "weekly"` must be invalid once the inclusion list is updated (red: currently valid). Tag with `# [REQ-HAB-005]` per `.cursor/rules/spec-req-traceability.mdc`.</step>

  <step id="3" status="complete">Add a Rails data migration on `user_habits`: for each row with `frequency_type == "weekly"`, set `frequency_type` to `weekdays` and set `frequency_params["weekdays"]` to a single-element array. Mapping rule (document in migration comment): use first valid integer from legacy `frequency_params["weekdays"]` if present; else `frequency_params["weekday"]` if present; else `activation_date.wday` when `activation_date` present; else `0`. Merge other keys only if needed for backward compatibility; goal is valid `weekdays` shape per existing validations.</step>

  <step id="4" status="complete">Update `UserHabit`: remove `weekly` from `frequency_type` inclusion; delete the `when "weekly"` branch in `frequency_requirements`. Re-run model specs until the new example and existing suite pass.</step>

  <step id="5" status="pending">Update `docs/core/SPEC.md`: glossary “Frequency type” row and REQ-HAB-005 text — canonical types `daily`, `weekdays`, `every_x_days`, `monthly` only; document that former `weekly` semantics are expressed as `weekdays` with a one-element array. Adjust status line if needed. Obey spec registry conventions.</step>

  <step id="6" status="pending">Repository sweep: `GlobalHabitTemplate` / seeds / factories / controllers / views / i18n for habit `weekly`; replace with `weekdays` and appropriate params where a weekly-like habit was intended. Run full `bundle exec rspec` again and fix regressions.</step>
</implementation_plan>
