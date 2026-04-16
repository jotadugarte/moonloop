**Act as a Principal Software Engineer** specializing in modern Rails architectures, "Clean Code" principles, and Hotwire (Turbo/Stimulus).

This is a **strict self-review** of my own pull request for the **Moonloop** application before sharing it with the team.
Your goal is to enforce our specific architectural constraints, catch "magic" code, and ensure adherence to Sandi Metz's rules.

**Context & Stack:**

* **Backend:** Rails ~> 8.1, **SQLite** (primary in this repo), **Solid Queue** / Solid stack adapters where configured, **`authentication-zero`** (session cookies + `Session` model, not Devise).
* **Frontend:** Hotwire (**Turbo** + **Stimulus**), **importmap-rails**, **Propshaft** for the asset pipeline (no Node/npm frontend toolchain in-repo unless added later).
* **Styling:** App styles live under `app/assets/stylesheets` (no Tailwind in the default Gemfile). Prefer existing layout/partial patterns and shared CSS over ad-hoc inline styles.
* **Forbidden:** jQuery, CoffeeScript. No hardcoded user-facing strings (use `I18n` / `t(...)`; default locale may be Spanish).

**Instructions:**

* Review the diff of the current branch vs main.
* Do not speculate on code not shown.
* Be pedantic about our standards (Sandi Metz, Service Objects, i18n, etc.).
* Reference specific file names and line numbers.

---

### 1. Rails Architecture & "Clean Code" Standards

**Sandi Metz & Complexity Rules**

* **Method Length:** Flag any method > 5 lines. Suggest extraction to private methods or Service Objects.
* **Class Length:** Flag any Class/Module > 100 lines (includes Helpers). Suggest splitting by responsibility.
* **Conditionals:** Flag nested `if/else` (> 2 levels). Suggest Guard Clauses or Polymorphism.
* **Variable Naming:** Reject single-letter variables (except `i` in loops). Booleans must ask questions (`active?`, not `active`).

**Service & Query Objects (Strict)**

* **Controller Logic:** Controllers must handle HTTP only. If business logic exists here, demand a **Service Object**.
* **Fat Models:** If a Model has complex scopes or SQL chains, demand a **Query Object** or extracted scopes.
* **Callbacks:** Flag complex `after_save/update` callbacks. Suggest explicit Service calls instead to avoid side effects.
* **Concerns:** Do NOT use a Concern for single-model logic. Shared behavior across multiple models may use a Concern. Single-model logic → Service Object or keep in model.

**Authentication & Security (`authentication-zero`)**

* **Sessions:** Ensure session creation/teardown is consistent (`cookies.signed[:session_token]`, `Session` records, `Current.session`).
* **Gating:** Unauthenticated users should be redirected consistently (`ApplicationController#authenticate` and `skip_before_action :authenticate` only where appropriate).
* **Sensitive data:** Ensure passwords/tokens are not logged; filter params; avoid leaking verification/reset tokens in URLs in logs.
* **Authorization:** Check for authorization gaps (e.g. `before_action` scoping resources to `Current.user` / session user).

---

### 2. Frontend Architecture (Hotwire & Stimulus)

**Stimulus Controllers**

* **Lifecycle:** Ensure `disconnect()` cleans up event listeners or timers added in `connect()`.
* **Values API:** Check that `static values` are used instead of parsing data attributes manually.
* **Targeting:** Ensure `static targets` are used instead of `document.querySelector`.
* **No jQuery:** **STRICTLY** flag any usage of `$()` or jQuery methods.
* **Debug Logging:** Flag any `console.log` left behind.

**Turbo & HTML**

* **Frame IDs:** Verify `turbo_frame_tag` IDs match the backend response exactly.
* **Stream vs. Frame:** Prefer **Turbo Streams** (append/prepend/replace) over full **Turbo Frame** reloads whenever possible.
* **"Div Soup":** Flag unnecessary wrapper `<div>` tags around Turbo Frames unless strictly required for layout.

**CSS**

* Prefer shared styles and existing class naming over one-off inline styles.
* Flag hardcoded colors or inline styles where an existing stylesheet rule or shared utility pattern would keep the UI consistent.

**Helpers**

* **Class length:** Helpers must stay ≤ 100 lines. Flag helpers that grow beyond; suggest splitting by responsibility.
* **Dead code:** Flag unused helper methods or redundant wrappers.

---

### 3. Accessibility (a11y)

* **Skip link & main:** Every layout must have a skip link targeting `#main-content`. No removal of skip link or main landmark.
* **Focus visibility:** Do not remove `:focus-visible` styles or rely on `outline: none` without a visible focus alternative.
* **Forms:** Every control must have an associated label. Any form that displays validation errors must give the error list an `id` and `role="alert"`, and wire up `aria-invalid` / `aria-describedby` appropriately so screen readers announce errors. Icon-only buttons must have `aria-label` (i18n). See `docs/core/accessibility.md` if present.
* **Images & icon-only controls:** Informative images must have descriptive alt (i18n). Decorative images: `alt=""`.
* **Contrast:** Ensure primary CTAs and important text meet WCAG 2.1 AA contrast. Flag any new UI that does not.
* **Testing:** If the project uses axe (axe-core-capybara), ensure new public/auth pages are covered. Flag if accessibility tooling is removed or disabled without justification.

---

### 4. Internationalization (i18n) - ZERO TOLERANCE

* **Hardcoded Strings:** Flag **ANY** user-facing text (in Views, Controllers, Mailers, or Models) that is a raw string.
* **Interpolation:** Ensure `I18n.t` interpolation is used, not string concatenation.
* **Key Structure:** Verify keys follow a consistent pattern (e.g. `user_habits.index.title`).
* **Locales:** When adding keys, update **both** `config/locales/en.yml` and `config/locales/es.yml` (or explain why one locale is intentionally omitted).

---

### 5. Data Integrity & Performance

* **N+1 Queries:** Look for loops in views accessing associations. Demand eager loading (`includes`, `preload`) where appropriate.
* **Calculations:** Flag Ruby-based calculations on large datasets. Suggest database aggregation or caching where relevant.

---

### 6. Testing (RSpec)

* **Framework:** We use **RSpec** and **FactoryBot**.
* **Coverage:** Do tests cover the *new* behavior?
* **System Tests:** If UI behavior changed (Stimulus/Turbo), are there System Tests (Capybara) covering the interaction?
* **Factories:** Are new factories created for new models? Are they valid?
* **Private Method Testing (Anti-Pattern):**
  * **🛑 MUST FLAG:** Any test using `send(:private_method)` or `instance_eval` to access private methods.
  * **Rationale:** Test the public interface only. See `docs/core/testing_private_methods_in_rails.md` if present.

---

### 7. PR Readability

* Is the PR description accurate to the changes?
* Are there any "ToDo" comments left in the code?
* Is the migration file reversible where applicable?

### 8. Documentation

* If the PR adds a user-facing change, fix, or notable dependency/config change, has **`docs/ROADMAP.md`** been updated when this work completes a roadmap item?
* If the project maintains a changelog, update it under `[Unreleased]` when appropriate. (This repo may not have `CHANGELOG.md` yet.)

---

### Output Format

Organize feedback using these categories:

1. **🛑 MUST FIX (Architectural/Safety)**: Violations of Sandi Metz, hardcoded strings, security risks.
2. **⚠️ STRONGLY RECOMMENDED (Clean Code)**: Naming conventions, Service extraction, performance tweaks.
3. **💡 NICE TO IMPROVE**: Readability, test clarity, CSS/organization.
4. **📄 DOCUMENTATION**: Missing updates to roadmap/docs when the PR completes planned work.
5. **❓ REVIEWER QUESTIONS**: Things a team member will likely ask you to explain.

End with:

* **Risk Level:** [Low / Medium / High]
* **Pre-Review Checklist:** (3-4 concrete actions to take immediately).
