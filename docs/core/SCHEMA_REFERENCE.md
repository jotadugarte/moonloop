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
| `menus` | `user_id` FK | `REQ-MENU-001`. User-owned weekly templates; `publicly_shareable` for catalog |
| `menu_entries` | Unique `(menu_id, weekday, meal_type)`; FKs to `menus`, optional `recipes` | `REQ-MENU-001`. Sparse rows; `meal_type` + `weekday` index the grid slot |
| `recipes` | `user_id` FK | `REQ-MENU-002`. Optional instructions; image via Active Storage; `publicly_shareable` |

---

## Phase plan and reminders

| Table | Primary keys / constraints | SPEC / notes |
|--------|----------------------------|--------------|
| `phase_assignments` | `user_id`, `menu_id` FKs; check `start_week >= 1`, `end_week >= start_week` | `REQ-MENU-003`. Non-overlapping ranges enforced in the model |
| `phase_reminder_events` | Unique `(user_id, kind, local_date)` | `REQ-MENU-004`. Idempotent reminder bookkeeping |

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

## Habits, Mi Día, auth (existing)

Tables `users` (non-phase columns), `sessions`, `habit_categories`, `global_habit_templates`, `user_habits`, `habit_completions`, `weight_logs` support Phases 1–3 as described in `SPEC.md` and earlier sections of `DATA_FLOW_MAP.md`.

---

## Foreign keys (excerpt)

Rails adds FKs from `menu_entries` → `menus`, `recipes`; `menus` / `recipes` → `users`; `phase_assignments` → `users`, `menus`; `phase_reminder_events` → `users`; Active Storage tables per `db/schema.rb`.
