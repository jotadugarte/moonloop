# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Added

- Phase 5 — **Exercise routines**: weekly routine lines per weekday, week-range assignments on `/phase` (same anchor as menus), Mi Día integration for `fitness_exercise`, dual “plan ended” / repeat-last for menu vs routine lanes, CRUD + duplicate + transactional delete with assignment cascade, home and plan entry points, and REQ coverage for `REQ-EXR-001`–`REQ-EXR-005` (see `docs/core/SPEC.md`).
- Phase 4 — **Alimentación**: weekly **menus** (sparse grid + Turbo slot updates), **recipes** with Active Storage images and public sharing, **phase plan** (anchor date, week assignments, active menu resolution), **phase start reminders** (Solid Queue sweep + in-app banner with dismiss-for-today), **plan-ended** extension UX (repeat last assignment or new range), admin moderation to revoke public sharing on menus/recipes, Mi Día shortcut to the phase area, and REQ coverage for `REQ-MENU-001`–`REQ-MENU-005` (see `docs/core/SPEC.md`).

### Changed

- Habits: removed `weekly` as a `frequency_type`; “once per week” is stored as `weekdays` with a one-element array. Data migration copies legacy rows using a **nested frozen resolver** (no dependency on `app/` autoload). `Habits::LegacyWeeklyWeekdayResolver` mirrors that logic for tests and tooling (REQ-HAB-005). `Habits::NextOccurrence` covers `daily`, `weekdays`, `every_x_days`, and `monthly`, aligned with `Habits::DueOnDate` for schedule types used in Mi Día.

### Added

- Phase 3 — **Mi Día**: `habit_completions` persistence, `Habits::DueOnDate` / streak / completion services, “Mi Día” screen with date navigation, mark done/failed/clear, and roadmap REQ-DAY-001–004 (see `docs/core/SPEC.md`).
- Phase 2 — Habits core: global templates, per-user categories and habits, default provisioning job on sign-in, frequency fields and validations, habits UI (grouped listing, personal habit, add from template, activate/deactivate).
- Internationalization: Spanish default locale, English secondary; shared Active Record error messages and habit/user copy.
- Requirements registry and REQ-ID comments in RSpec; Cursor rules for SPEC/spec traceability.
- `docs/core/SPEC.md` and `docs/core/SYSTEM_ARCHITECTURE.md` aligned with the Moonloop stack (authentication-zero, Propshaft, Hotwire, SQLite).

### Fixed

- Sign-up form uses `model: @user` and `params.require(:user)` so labels match i18n and system specs can find fields.
