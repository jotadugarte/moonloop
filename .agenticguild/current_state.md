# Agentic Guild — current state

- <active_task_pointer>.agenticguild/active_sessions/task_menus-combobox-por-tipo-de-comida.md</active_task_pointer>
- **Phase:** code-review (Implementation & Verification Loop)
- **Step:** 2.1 Apply requested fixes + await local verification
- **Context:** Removed DB queries from `menus/_slot`, made dish picker single-source-of-truth (hidden field), and moved dishes preload/grouping to `MenusController#load_menu_editor`.
- **Next:** User runs bundle + targeted specs; then reply with results.
