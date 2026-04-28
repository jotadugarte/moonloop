# Agentic Guild — current state

- <active_task_pointer>.agenticguild/active_sessions/task_bug-menus-combobox-agrupado-y-filtro.md</active_task_pointer>
- **Phase:** finish-branch (Interactive Local Review → code-review)
- **Step:** code-review 2.1 Implement requested fixes + run tests/linters
- **Context:** Fixed Turbo slot render locals to include `dishes_by_id` (required by `menus/_slot`). Ready to re-run system specs.
- **Next:** Rerun `bundle exec rspec spec/system/menus_autosave_spec.rb` and paste failures if any.
