# Schema reference

**Purpose:** Map Active Record tables to requirements and domain concepts in `docs/core/SPEC.md`. Structure reflects `db/schema.rb` (authoritative for column types and indexes).

**Maintenance:** Update this file when migrations add or change tables material to the product domain. Session/task notes may justify short “why/when” annotations per table.

---

## Active Storage

| Table | Role |
|--------|------|
| `active_storage_blobs` | Binary metadata for uploaded files |
| `active_storage_attachments` | Polymorphic link from records (e.g. `Recipe` image) to blobs |
| `active_storage_variant_records` | Derived image variants when using `image_processing` |

**Semantics:** Recipe images use **`has_one_attached :image`** (`REQ-MENU-002`). Variants are applied only when the blob is **variable** (see `ApplicationHelper#attachable_image_tag`).

---

## Menus and recipes

| Table | Primary keys / constraints | SPEC / notes |
|--------|----------------------------|--------------|
| `menus` | `user_id` FK; optional self-FK `source_menu_id`; partial unique `(user_id, source_menu_id)` where source present; unique `(user_id, name_normalized)`; `source_sync_fingerprint`, `adoption_catalog_origin_id` (adoption/sync, **REQ-MENU-006**) | `REQ-MENU-001`, **REQ-MENU-006**. Weekly templates; catalog opt-in; adopted-copy metadata |
| `menu_entries` | Unique `(menu_id, weekday, meal_type)`; FKs to `menus`, optional `recipes` | `REQ-MENU-001`. Sparse rows; `meal_type` + `weekday` index the grid slot |
| `recipes` | `user_id` FK | `REQ-MENU-002`. Optional instructions; image via Active Storage; `publicly_shareable` |

---

## Phase plan and reminders

| Table | Primary keys / constraints | SPEC / notes |
|--------|----------------------------|--------------|
| `phase_assignments` | `user_id`, `menu_id` FKs; check `start_week >= 1`, `end_week >= start_week` | `REQ-MENU-003`. Non-overlapping ranges enforced in the model |
| `phase_reminder_events` | Unique `(user_id, kind, local_date)` | `REQ-MENU-004`. Idempotent reminder bookkeeping |

---

## Exercise routines

| Table | Primary keys / constraints | SPEC / notes |
|--------|----------------------------|--------------|
| `exercise_routines` | `user_id` FK; optional self-FK `source_exercise_routine_id` (nullable); unique `(user_id, name_normalized)`; partial unique `(user_id, source_exercise_routine_id)` where source present; `publicly_shareable` (default false); `source_sync_fingerprint`, `adoption_catalog_origin_id` (adoption/sync, **REQ-EXR-006**) | `REQ-EXR-001`, **REQ-EXR-006**. User-owned named routines; not globally empty (≥1 line on ≥1 weekday); optional public catalog and adopted-copy metadata |
| `exercise_routine_lines` | FK to `exercise_routines`; unique `(exercise_routine_id, weekday, position)`; `weekday` 0–6; `label` max 500 | `REQ-EXR-001`. Ordered lines per weekday |
| `exercise_routine_assignments` | `user_id`, `exercise_routine_id` FKs; check `start_week >= 1`, `end_week >= start_week` | `REQ-EXR-002`. Non-overlapping ranges per user among **routine** assignments only (independent from `phase_assignments`) |

**Semantics:** Program week index and anchor are shared with menus via `users.phase_one_starts_on` and `Phases::WeekNumber` (`REQ-EXR-002`). Deleting a routine after confirmation removes dependent `exercise_routine_assignment` rows then the routine in one transaction (`REQ-EXR-001` Q12).

---

## Users (phase-related columns)

| Column | Meaning |
|--------|---------|
| `phase_one_starts_on` | Phase 1 anchor date (nullable) |
| `phase_reminder_in_app` | In-app phase-start reminder enabled |
| `phase_reminder_email` | Email phase-start reminder enabled |
| `phase_reminder_dismissed_on` | Local date for which in-app banner was dismissed |
| `allow_menu_freeform` | When false, UI hides freeform slot input (legacy freeform may still display read-only) |

See `REQ-MENU-001`, `REQ-MENU-003`, `REQ-MENU-004`.

---

## Weight logs

| Table | Primary keys / constraints | SPEC / notes |
|--------|----------------------------|--------------|
| `weight_logs` | `user_id` FK; `logged_at` **NOT NULL** (product timeline, stored in UTC); `weight_kg`, `height_cm`, `bmi` snapshots; `created_at` / `updated_at` for audit | `REQ-WGT-001`–`003`. Index **`(user_id, logged_at)`** for listing; ordering for history is **`logged_at DESC`, `id DESC`**. `weight_kg` / `height_cm` are **readonly** after create (corrections via delete + new entry). |

See **§1.8 Weight log** in `DATA_FLOW_MAP.md` for write flows and `User` **`current_weight_kg` / `current_bmi`** reconciliation.

---

## Habits, Mi Día, auth (existing)

Tables `users` (non-phase columns), `sessions`, `habit_categories`, `global_habit_templates`, `user_habits`, `habit_completions` support Phases 1–3 as described in `SPEC.md` and earlier sections of `DATA_FLOW_MAP.md`. Weight logging is covered above.

**`habit_completions` (habit metrics, REQ-DAY-005):** in addition to `status` (`done` \| `failed`) and optional accumulated **`day_progress`** for measurable habits, **`marked_failed_by_user`** (boolean, default false) records whether the user explicitly chose failure for that day. Streaks and reports still key off persisted **`status`** and the same fulfillment rules as Mi Día; the flag exists so the Mi Día UI can show an **in progress** label when `status` is `failed` only because progress is below the daily target, without conflating that with an explicit user failure. See the *Habit completion* glossary in `SPEC.md`.

---

## Foreign keys (excerpt)

Rails adds FKs from `menu_entries` → `menus`, `recipes`; `menus` / `recipes` → `users`; `phase_assignments` → `users`, `menus`; `exercise_routine_assignments` → `users`, `exercise_routines`; `exercise_routine_lines` → `exercise_routines`; `exercise_routines` → `users`; `phase_reminder_events` → `users`; Active Storage tables per `db/schema.rb`.
