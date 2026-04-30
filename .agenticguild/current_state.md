<phase>roadmap-manage</phase>
<step>1.2</step>

Context loaded:
- Read `docs/ROADMAP.md` (latest includes Done items #43, #46, #48, #50, #54, #55, #56, #58, #59, #52, etc.)
- Listed `.agenticguild/active_sessions/` (13 markdown files).

Next:
- Map each active session to ROADMAP items and determine done vs pending.
- Move ready sessions to `.agenticguild/completed_sessions/`.
- Leave remaining sessions in `.agenticguild/active_sessions/` with rationale recorded in this state file.

Decision snapshot (pre-move):
- Move (done in ROADMAP + session steps complete): #46, #47, #48, #52, #54, #55, #56.
- Keep active (not clearly closed / handoff / mismatch): exercise-routines i18n, template.

Executed:
- Archived + moved to completed_sessions: #43, #58, #59, roadmap-quick-wins.
- Active_sessions now contains only: task_exercise-routines-i18n-validaciones.md, task_template.md.

# Agentic Guild — current state

- <active_task_pointer>.agenticguild/active_sessions/task_bug-menus-combobox-agrupado-y-filtro.md</active_task_pointer>
- **Phase:** deploy-fly
- **Step:** 1.1 Validate Fly config + CLI permissions
- **Context:** `fly.toml` present for app `moonloop` (primary region `iad`, `PORT=8080`, health check `GET /up`). Repo clean (`git status -sb` shows no local changes). `flyctl` fails in sandbox due to permission error writing to `~/.fly`.
- **Next:** Run `flyctl deploy` outside sandbox (or from user's terminal) and verify health check.
