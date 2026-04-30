# Agentic Guild — current state

- <active_task_pointer>.agenticguild/active_sessions/task_bug-menus-combobox-agrupado-y-filtro.md</active_task_pointer>
- **Phase:** deploy-fly
- **Step:** 1.1 Validate Fly config + CLI permissions
- **Context:** `fly.toml` present for app `moonloop` (primary region `iad`, `PORT=8080`, health check `GET /up`). Repo clean (`git status -sb` shows no local changes). `flyctl` fails in sandbox due to permission error writing to `~/.fly`.
- **Next:** Run `flyctl deploy` outside sandbox (or from user's terminal) and verify health check.
