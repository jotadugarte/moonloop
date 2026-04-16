# System Architecture & Boundaries

**Purpose:** Technical boundaries for Moonloop. Changes that contradict this document need an explicit ADR or product decision, not silent drift.

## 1. Technology stack

| Layer | Choice |
|--------|--------|
| **Language / runtime** | Ruby 3.3.x (see `.ruby-version`) |
| **Framework** | Ruby on Rails ~> 8.1 |
| **App server** | Puma |
| **Database** | SQLite3 (development, test, and default production posture in this repo) |
| **Assets** | Propshaft; JavaScript via `importmap-rails` (no default Node/npm asset pipeline) |
| **Frontend** | Hotwire: `turbo-rails`, `stimulus-rails`; server-rendered ERB |
| **Auth** | `authentication-zero` + `has_secure_password` (session records, signed cookie); not Devise |
| **Background / infra gems** | `solid_cache`, `solid_queue`, `solid_cable` (Rails 8 Solid stack) |
| **Deploy (optional)** | Kamal, Thruster (see Gemfile) |
| **Tests** | RSpec, FactoryBot, Capybara, Selenium (system specs) |

## 2. Architectural paradigm

- **Server-rendered first:** Controllers render HTML; Turbo handles navigation and forms unless explicitly disabled.
- **Thin controllers:** Non-trivial workflows go to **service objects** under `app/services/` (e.g. `Habits::*`, `Auth::*`).
- **Domain rules in models** where they are simple validations and associations; extract when complexity or cross-cutting orchestration grows.
- **Internationalization:** Default locale `es`; `en` available. User-visible strings go through `I18n` / `t(...)`.
- **Traceability:** Requirements live in `docs/core/SPEC.md` (`REQ-*` IDs). Specs use `# [REQ-…]` comments per `.cursor/rules/spec-req-traceability.mdc`.
- **Immutable migration logic:** One-off **data** migrations that rewrite legacy column values (for example normalizing `user_habits.frequency_type`) must **not** call arbitrary `app/services` classes from `db/migrate`, so fresh `db:migrate` runs do not depend on Zeitwerk autoload or on later refactors of application code. Keep a **frozen resolver** colocated with the migration (nested class on the migration, e.g. `MigrateWeeklyUserHabitsToWeekdays::WdayResolver`). When the same rules are needed for **automated tests or tooling**, mirror them in a small, spec-covered service under `app/services/` (e.g. `Habits::LegacyWeeklyWeekdayResolver`) and state in comments on **both** sides that behavior must stay aligned.
- **Markup in ERB:** Views may use utility-style class names (for example Tailwind-like `text-2xl`, `border-gray-300`) with styles supplied under `app/assets/stylesheets`. The Gemfile does not include `tailwindcss-rails` unless that pipeline is adopted explicitly.

## 3. Forbidden or discouraged (without ADR)

- **jQuery** or **CoffeeScript** for new frontend code.
- **Devise** (or parallel auth frameworks) while the app is standardized on authentication-zero.
- **Hardcoded user-facing strings** in views, controllers, flash, or mailers (use I18n keys).
- **Introducing a Node-based bundler** (Webpack/Vite) for the default asset path unless an ADR accepts the operational cost.
- **Fat controllers** that encode business rules that belong in services or the domain layer.

## 4. Environment and infrastructure

- **Configuration:** Rails credentials and environment-specific config under `config/`.
- **Jobs:** Active Job with Solid Queue where enabled; tests use the test adapter unless configured otherwise.
- **Browser support:** `ApplicationController` restricts to modern browsers per `allow_browser versions: :modern`.

## 5. Related documents

- `docs/core/SPEC.md` — requirements registry and glossary.
- `docs/ROADMAP.md` — phased delivery.
- `docs/ai/code_review_prompt.md` — self-review checklist aligned to this stack.
