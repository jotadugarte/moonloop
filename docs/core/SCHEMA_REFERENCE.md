# Schema reference

**Purpose:** Map Active Record tables to requirements and domain concepts in `docs/core/SPEC.md`. Structure reflects `db/schema.rb` (authoritative for column types and indexes; now running on PostgreSQL with a strict 1:1 translation from the original SQLite schema).

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
| `menus` | `user_id` FK; optional self-FK `source_menu_id`; partial unique `(user_id, source_menu_id)` where source present; unique `(user_id, name_normalized)`; `source_sync_fingerprint`, `adoption_catalog_origin_id` (adoption/sync, **REQ-MENU-006**); **`public_catalog_adoptions_count`**, **`public_catalog_distinct_adopters_count`** (integer, default 0, NOT NULL, **REQ-CAT-001**) | `REQ-MENU-001`, **REQ-MENU-006**, **REQ-CAT-001**. Weekly templates; catalog opt-in; adopted-copy metadata; template-level catalog popularity metrics |
| `menu_entries` | Unique `(menu_id, weekday, meal_type)`; FKs to `menus`, optional `recipes` | `REQ-MENU-001`. Sparse rows; `meal_type` + `weekday` index the grid slot |
| `recipes` | `user_id` FK; `meal_type` (string, NOT NULL, default `"desayuno"`, indexed with `user_id`) | `REQ-MENU-002`. Optional instructions; image via Active Storage; `publicly_shareable`. `meal_type` drives per-meal placeholder fallback assets |

---

## Phase plan and reminders

| Table | Primary keys / constraints | SPEC / notes |
|--------|----------------------------|--------------|
| `phase_assignments` | `user_id`, `menu_id` FKs; check `start_week >= 1`, `end_week >= start_week` | `REQ-MENU-003`. Non-overlapping ranges enforced in the model |
| `phase_reminder_events` | Unique `(user_id, kind, local_date)` | `REQ-MENU-004`. Idempotent reminder bookkeeping |

---

## Habit reminders (per-habit)

| Table | Primary keys / constraints | SPEC / notes |
|--------|----------------------------|--------------|
| `habit_reminder_events` | Unique `(user_id, user_habit_id, local_date)` | **REQ-HAB-011**. Idempotent bookkeeping that the per-habit reminder pipeline ran for that **user-local day** (prevents duplicate processing on retries); does not assert email delivery or push receipt |
| `web_push_subscriptions` | Unique `(user_id, endpoint)`; required `endpoint`, `p256dh`, `auth` | **REQ-HAB-012** (persistence + HTTP subscribe/unsubscribe). **REQ-HAB-013** sends encrypted payloads to each row when a habit reminder fires; dead endpoints are deleted. See **`docs/core/ADRs/0001-habit-reminders-web-push.md`** |

### `user_habits` reminder columns

`user_habits` stores per-habit reminder configuration (MVP):

- `reminder_enabled` (boolean, default false)
- `reminder_time_of_day` (string `HH:MM`, interpreted in the user’s IANA timezone)
- `reminder_email` (boolean, default false)
- `reminder_web_push` (boolean, default false)

See **REQ-HAB-010** for validation rules and eligibility (inactive habits are not eligible).

---

## Phase programs (bundles)

| Table | Primary keys / constraints | SPEC / notes |
|--------|----------------------------|--------------|
| `phase_programs` | `user_id` FK; optional self-FK `source_phase_program_id` (nullable); unique `(user_id, name_normalized)`; partial unique `(user_id, source_phase_program_id)` where source present; `publicly_shareable` (default false); `source_sync_fingerprint`, `adoption_catalog_origin_id` (adoption/sync, **REQ-PHS-001**, parity **REQ-MENU-006** / **REQ-EXR-006**); **`public_catalog_adoptions_count`**, **`public_catalog_distinct_adopters_count`** (integer, default 0, NOT NULL, **REQ-CAT-001**) | **REQ-PHS-001**, **REQ-CAT-001**. User-owned named program template; catalog and adopted-copy metadata; template-level catalog popularity metrics |
| `phase_program_assignments` | FKs to `phase_programs`, `menus`, `exercise_routines`; check `start_week >= 1`, `end_week >= start_week`; index `(phase_program_id, start_week, end_week)` | **REQ-PHS-001**. Week-range rows pairing menu + routine **within one program**; non-overlapping ranges enforced in the model (independent from global `phase_assignments` / `exercise_routine_assignments`) |

---

## Exercise routines

| Table | Primary keys / constraints | SPEC / notes |
|--------|----------------------------|--------------|
| `exercise_routines` | `user_id` FK; optional self-FK `source_exercise_routine_id` (nullable); unique `(user_id, name_normalized)`; partial unique `(user_id, source_exercise_routine_id)` where source present; `publicly_shareable` (default false); `source_sync_fingerprint`, `adoption_catalog_origin_id` (adoption/sync, **REQ-EXR-006**); **`public_catalog_adoptions_count`**, **`public_catalog_distinct_adopters_count`** (integer, default 0, NOT NULL, **REQ-CAT-001**) | `REQ-EXR-001`, **REQ-EXR-006**, **REQ-CAT-001**. User-owned named routines; not globally empty (≥1 line on ≥1 weekday); optional public catalog and adopted-copy metadata; template-level catalog popularity metrics |
| `exercise_routine_lines` | FK to `exercise_routines`; unique `(exercise_routine_id, weekday, position)`; `weekday` 0–6; `label` max 500 | `REQ-EXR-001`. Ordered lines per weekday |
| `exercise_routine_assignments` | `user_id`, `exercise_routine_id` FKs; check `start_week >= 1`, `end_week >= start_week` | `REQ-EXR-002`. Non-overlapping ranges per user among **routine** assignments only (independent from `phase_assignments`) |

**Semantics:** Program week index and anchor are shared with menus via `users.phase_one_starts_on` and `Phases::WeekNumber` (`REQ-EXR-002`). Deleting a routine after confirmation removes dependent `exercise_routine_assignment` rows then the routine in one transaction (`REQ-EXR-001` Q12).

---

## Public catalog metrics & discovery (REQ-CAT-001)

**Status:** template **counter** columns are on **`menus`**, **`exercise_routines`**, and **`phase_programs`** (see those sections). **`catalog_listing_facets`** stores optional discovery metadata per listable. Definitions: **`docs/core/SPEC.md`** (`#### REQ-CAT-001`).

| Table | Primary keys / constraints | SPEC / notes |
|--------|----------------------------|--------------|
| `catalog_listing_facets` | Polymorphic **`listable_type`** / **`listable_id`**, **NOT NULL**; **unique** `(listable_type, listable_id)`; `goal_phrase` (255), `difficulty_level` (32, closed vocabulary in **`Catalog::ListingFacet`**), `normalized_tags` (500, comma-separated slugs), `duration_weeks_min` / `duration_weeks_max` (nullable integers); timestamps | **REQ-CAT-001**. At most one facet row per catalog listable (`Menu`, `ExerciseRoutine`, `PhaseProgram`); owner-only writes in app code; public catalog reads join only **public** templates |

**Template counters:** **`public_catalog_adoptions_count`** and **`public_catalog_distinct_adopters_count`** on **`menus`**, **`exercise_routines`**, and **`phase_programs`** (see rows in **Menus and recipes**, **Phase programs**, and **Exercise routines** above).

---

## Users (phase-related columns)

| Column | Meaning |
|--------|---------|
| `phase_one_starts_on` | Phase 1 anchor date (nullable) |
| `phase_reminder_in_app` | In-app phase-start reminder enabled |
| `phase_reminder_email` | Email phase-start reminder enabled |
| `phase_reminder_dismissed_on` | Local date for which in-app banner was dismissed |
| `allow_menu_freeform` | When false, UI hides freeform slot input (legacy freeform may still display read-only) |
| `body_unit_system` | Closed vocabulary **`metric`** \| **`imperial_us`**, NOT NULL, default **`metric`** (**REQ-PROF-003**, planned); canonical `height_cm` / `weight_kg` unchanged |

See `REQ-MENU-001`, `REQ-MENU-003`, `REQ-MENU-004`.

---

## Weight logs

| Table | Primary keys / constraints | SPEC / notes |
|--------|----------------------------|--------------|
| `weight_logs` | `user_id` FK; `logged_at` **NOT NULL** (product timeline, stored in UTC); `weight_kg`, `height_cm`, `bmi` snapshots; `created_at` / `updated_at` for audit | `REQ-WGT-001`–`003`. Index **`(user_id, logged_at)`** for listing; ordering for history is **`logged_at DESC`, `id DESC`**. `weight_kg` / `height_cm` are **readonly** after create (corrections via delete + new entry). |

See **§1.9 Weight log** in `DATA_FLOW_MAP.md` for write flows and `User` **`current_weight_kg` / `current_bmi`** reconciliation.

---

## Habits, Mi Día, auth (existing)

Tables `users` (non-phase columns), `sessions`, `habit_categories`, `global_habit_templates`, `user_habits`, `habit_completions` support Phases 1–3 as described in `SPEC.md` and earlier sections of `DATA_FLOW_MAP.md`. Weight logging is covered above.

**`habit_completions` (habit metrics, REQ-DAY-005):** in addition to `status` (`done` \| `failed`) and optional accumulated **`day_progress`** for measurable habits, **`marked_failed_by_user`** (boolean, default false) records whether the user explicitly chose failure for that day. Streaks and reports still key off persisted **`status`** and the same fulfillment rules as Mi Día; the flag exists so the Mi Día UI can show an **in progress** label when `status` is `failed` only because progress is below the daily target, without conflating that with an explicit user failure. See the *Habit completion* glossary in `SPEC.md`.

---

## Foreign keys (excerpt)

Rails adds FKs from `menu_entries` → `menus`, `recipes`; `menus` / `recipes` → `users`; `phase_assignments` → `users`, `menus`; `phase_program_assignments` → `phase_programs`, `menus`, `exercise_routines`; `phase_programs` → `users`, `phase_programs` (self, `source_phase_program_id`); `exercise_routine_assignments` → `users`, `exercise_routines`; `exercise_routine_lines` → `exercise_routines`; `exercise_routines` → `users`; `phase_reminder_events` → `users`; `habit_reminder_events` → `users`, `user_habits`; `web_push_subscriptions` → `users`; Active Storage tables per `db/schema.rb`.
