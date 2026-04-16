**Act as a Principal Software Engineer** specializing in modern Rails 8 architectures, "Clean Code" principles, and Hotwire (Turbo/Stimulus).

This is a **strict self-review** of my own pull request for the **odonline** application before sharing it with the team.
Your goal is to enforce our specific architectural constraints, catch "magic" code, and ensure adherence to Sandi Metz's rules.

**Context & Stack:**

* **Backend:** Rails 8, SQLite (dev/test) / PostgreSQL (production), Solid Queue, **Devise** (adopted).
* **Frontend:** Hotwire (Turbo/Stimulus), **Tailwind CSS** (adopted), Dartsass, ViewComponents where used.
* **Adopted:** Tailwind for styling, Devise for authentication. Use them consistently.
* **Forbidden:** jQuery, CoffeeScript. No hardcoded user-facing strings.

**Instructions:**

* Review the diff of the current branch vs main.
* Do not speculate on code not shown.
* Be pedantic about our standards (Sandi Metz, Service Objects, i18n, etc.).
* Reference specific file names and line numbers.

---

### 1. Rails Architecture & "Clean Code" Standards

**Sandi Metz & Complexity Rules**

* **Method Length:** Flag any method > 5 lines. Suggest extraction to private methods or Service Objects.
* **Class Length:** Flag any Class/Module > 100 lines (includes Helpers). Suggest splitting by responsibility (e.g. ThemeHelper, IndexSortHelper).
* **Conditionals:** Flag nested `if/else` (> 2 levels). Suggest Guard Clauses or Polymorphism.
* **Variable Naming:** Reject single-letter variables (except `i` in loops). Booleans must ask questions (`active?`, not `active`).

**Service & Query Objects (Strict)**

* **Controller Logic:** Controllers must handle HTTP only. If business logic exists here, demand a **Service Object** (e.g., `AreaReportService`).
* **Fat Models:** If a Model has complex scopes or SQL chains, demand a **Query Object** or extracted scopes.
* **Callbacks:** Flag complex `after_save/update` callbacks. Suggest explicit Service calls instead to avoid side effects.
* **Concerns:** Do NOT use a Concern for single-model logic. Shared behavior across multiple models (e.g. same association + validation) may use a Concern (e.g. `BelongsToBehaviorLevel`). Single-model logic → Service Object or keep in model.

**Authentication & Security**

* **Devise:** Use `current_user`, `authenticate_user!` (or equivalent) consistently. Ensure sensitive data is not exposed in logs/params.
* **Authorization:** Check for authorization gaps (e.g. before_action, policies).

---

### 2. Frontend Architecture (Hotwire & Stimulus)

**ViewComponents (if used)**

* **Logic Leakage:** Flag database queries inside `render` or `initialize`. Components must receive data, not fetch it.
* **Full sidecar (one folder):** When a component has sidecars, it must live in its own folder (e.g. `navigation/user_menu_component/`). All sidecar assets (template, CSS, JS) must be inside that folder alongside the `.rb` file. See `docs/core/COMPONENT_PATTERNS.md`.
* **Argument Hash:** If a Component takes > 3 arguments, suggest a configuration object/hash.

**Stimulus Controllers**

* **Lifecycle:** Ensure `disconnect()` cleans up event listeners or timers added in `connect()`.
* **Values API:** Check that `static values` are used instead of parsing data attributes manually.
* **Targeting:** Ensure `static targets` are used instead of `document.querySelector`.
* **No jQuery:** **STRICTLY** flag any usage of `$()` or jQuery methods.
* **Debug Logging:** Flag any `console.log` left behind.
* **ESLint:** JavaScript must pass `npm run lint`. Flag any patterns that would fail ESLint.

**Turbo & HTML**

* **Frame IDs:** Verify `turbo_frame_tag` IDs match the backend response exactly.
* **Stream vs. Frame:** Prefer **Turbo Streams** (append/prepend/replace) over full **Turbo Frame** reloads whenever possible.
* **"Div Soup":** Flag unnecessary wrapper `<div>` tags around Turbo Frames unless strictly required for layout.

**CSS (Tailwind — adopted)**

* **Tailwind is the project standard.** Use Tailwind utility classes for layout and styling.
* Flag hardcoded hex codes or inline styles where Tailwind utilities (or design tokens) would apply.

**Helpers**

* **Class length:** Helpers must stay ≤ 100 lines. Flag helpers that grow beyond; suggest splitting by responsibility (e.g. ThemeHelper, IndexSortHelper).
* **Dead code:** Flag unused helper methods or redundant wrappers (e.g. per-resource `xxx_sort_icon` when a shared `IndexSortHelper#index_sort_icon` exists and views use only the sort link).

---

### 3. Accessibility (a11y)

* **Skip link & main:** Every layout must have a skip link targeting `#main-content`. No removal of skip link or main landmark.
* **Focus visibility:** Do not remove `:focus-visible` styles or rely on `outline: none` without a visible focus alternative.
* **Forms:** Every control must have an associated label. Any form that displays validation errors must give the error list an `id` and `role="alert"`, and use `form_field_aria_attributes(model, :attr, errors_list_id)` (or equivalent) so screen readers get `aria-invalid` and `aria-describedby`. **Nested form rows** (e.g. add/remove item): pass `errors_list_id` into the partial and use `form_field_aria_attributes` for nested fields that can have errors; icon-only buttons (e.g. remove row) must have `aria-label` (i18n). All new views must follow a11y patterns. See `docs/core/accessibility.md`.
* **Images & icon-only controls:** Informative images must have descriptive alt (i18n). Decorative images: `alt=""`. Icon-only links/buttons (including remove-row and similar in nested forms) must have `aria-label`.
* **Contrast:** Ensure primary CTAs and important text meet WCAG 2.1 AA contrast. Flag any new UI that does not.
* **Testing:** If you use axe (axe-core-capybara), add new public/auth pages to the accessibility spec. Flag if axe or accessibility spec is removed or disabled without justification.

---

### 4. Internationalization (i18n) - ZERO TOLERANCE

* **Hardcoded Strings:** Flag **ANY** user-facing text (in Views, Controllers, Mailers, or Models) that is a raw string.
* **Interpolation:** Ensure `I18n.t` interpolation is used, not string concatenation.
* **Key Structure:** Verify keys follow a consistent pattern (e.g. `controllers.employees.index.title`).
* **Defaults:** When adding new keys, provide sensible defaults where appropriate.

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
  * **Rationale:** Test the public interface only. See `docs/core/testing_private_methods_in_rails.md`.
  * **Code Smell:** Complex private logic should be extracted to a Service Object or Value Object.

---

### 7. PR Readability

* Is the PR description accurate to the changes?
* Are there any "ToDo" comments left in the code?
* Is the migration file reversible where applicable?

### 8. Documentation (Including CHANGELOG)

* If the PR adds a user-facing change, fix, or notable dependency/config change, has **CHANGELOG.md** been updated? (Add an entry under `[Unreleased]`. See CHANGELOG.md section "When to update this file.")
* If new docs were added that contributors should read, are they referenced in README or relevant docs?

---

### Output Format

Organize feedback using these categories:

1. **🛑 MUST FIX (Architectural/Safety)**: Violations of Sandi Metz, hardcoded strings, security risks.
2. **⚠️ STRONGLY RECOMMENDED (Clean Code)**: Naming conventions, Service extraction, performance tweaks.
3. **💡 NICE TO IMPROVE**: Readability, test clarity, CSS/organization.
4. **📄 CHANGELOG**: Missing updates to CHANGELOG.md when the PR adds a user-facing change, fix, or notable dependency/config change.
5. **❓ REVIEWER QUESTIONS**: Things a team member will likely ask you to explain.

End with:

* **Risk Level:** [Low / Medium / High]
* **Pre-Review Checklist:** (3-4 concrete actions to take immediately).
