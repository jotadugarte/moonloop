# Agentic Guild — current state

- <active_task_pointer>.agenticguild/active_sessions/task_bug-menus-combobox-agrupado-y-filtro.md</active_task_pointer>
- **Phase:** finish-branch (Interactive Local Review → code-review)
- **Step:** code-review 2.1 Implement requested fixes + run tests/linters
- **Context:** Implemented all review items (picker a11y/close UX, slot preview refactor, avoid per-slot dish lookup). Test run blocked: Postgres expected at `127.0.0.1:5433` is not reachable; Docker daemon not available from this environment.
- **Next:** Start Postgres (Docker Desktop / local service) and rerun `bundle exec rspec spec/system/menus_autosave_spec.rb`.
