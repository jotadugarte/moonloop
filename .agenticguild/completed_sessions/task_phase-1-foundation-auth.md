# Task: phase-1-foundation-auth
**Goal:** Build the complete Rails 8 foundation for Moonloop: project setup, authentication, user profile (with date_of_birth, height, timezone), BMI auto-calculation, and weight/BMI history.

---

## Discovery Log

### Decisions Made

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | `date_of_birth` instead of `age` integer | Age becomes stale; DOB is the stable source of truth. Age computed on demand. |
| 2 | `authentication-zero` gem, no extra flags | Simple email+password+sessions. No `--resetable`, no `--verifiable` for MVP. |
| 3 | All profile fields collected at signup | `email`, `password`, `date_of_birth`, `height_cm`, `timezone` — one step, no deferred setup. |
| 4 | `height_cm` is immutable post-creation | Height doesn't change in adulthood; no edit UI needed. Enforced at model level. |
| 5 | Multiple `weight_log` entries allowed per day | Timestamps distinguish them. No artificial "one per day" constraint. |
| 6 | `weight_logs` stores `weight_kg`, `height_cm` (snapshot), `bmi` | Each entry is self-contained and auditable. BMI = weight / (height_m)². |
| 7 | Denormalized `current_weight_kg` + `current_bmi` on `users` | Efficient reads for dashboard (no subquery). Synced on every `weight_log` creation. |
| 8 | Timezone auto-detected from browser (`Intl.DateTimeFormat`) | Stimulus controller pre-fills the field at signup. User sees and can modify it. |
| 9 | RSpec (not Minitest) | `--skip-test` on `rails new`, then `rspec-rails` + `factory_bot_rails` + `shoulda-matchers`. |
| 10 | BMI precision: 2 decimal places | Medical standard. |
| 11 | All profile fields (except height) editable post-signup | Height immutable; everything else editable via `ProfilesController`. |

### Roadmap Update Required

Update Phase 6 items #23–24 to explicitly mention BMI (roadmap renumbered after Phase 3 items):
- #23: Weight log: record entries (date+time, kg, bmi, height snapshot) — **Depends on: Phase 1**
- #24: Weight + BMI history view — **Depends on: #23**

---

## Domain Model

> ✅ **APPROVED — Value Objects as separate Ruby classes (`Data.define`), living in `app/values/`.**

### Value Object Implementations

```ruby
# app/values/height_cm.rb
HeightCm = Data.define(:value) do
  def initialize(value:)
    v = Integer(value)
    raise ArgumentError, "HeightCm must be 50–300, got #{v}" unless (50..300).cover?(v)
    super(value: v)
  end
end

# app/values/weight_kg.rb
WeightKg = Data.define(:value) do
  def initialize(value:)
    v = BigDecimal(value.to_s)
    raise ArgumentError, "WeightKg must be 20–500, got #{v}" unless (20..500).cover?(v)
    super(value: v)
  end
end

# app/values/bmi_value.rb
BmiValue = Data.define(:value) do
  def self.compute(weight_kg:, height_cm:)
    bmi = BigDecimal(weight_kg.to_s) / (BigDecimal(height_cm.to_s) / 100) ** 2
    new(value: bmi.round(2))
  end
end

# app/values/iana_timezone.rb
IanaTimezone = Data.define(:value) do
  VALID_ZONES = ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.name }.to_set.freeze

  def initialize(value:)
    raise ArgumentError, "Invalid IANA timezone: #{value}" unless VALID_ZONES.include?(value)
    super(value: value)
  end
end
```

### User
**Responsibility:** Owns identity + current health profile snapshot.
**Invariants:**
- Email must be unique and present.
- `height_cm` must be set at creation (as `HeightCm`) and never changed thereafter.
- `date_of_birth` must be in the past (minimum 10 years ago, maximum 120 years ago).
- `timezone` must be a valid `IanaTimezone`.
- `current_bmi` = `BmiValue.compute(weight_kg:, height_cm:)`. Only present if `current_weight_kg` is set.

### WeightLog
**Responsibility:** Immutable record of a weight measurement at a point in time.
**Invariants:**
- Always belongs to a User.
- `weight_kg` (`WeightKg`), `height_cm` (`HeightCm` snapshot), and `bmi` (`BmiValue`) are all required.
- `created_at` is the authoritative timestamp (multiple entries per day allowed).
- Records are never updated or deleted (append-only history).

---

## Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| authentication-zero strong params don't include custom fields | High | High | Explicitly extend `RegistrationsController#registration_params` to permit custom fields. |
| `height_cm` accidentally editable | Medium | Medium | `attr_readonly :height_cm` on model + no field in edit form. |
| Timezone select list mismatches Rails zones | Medium | High | Use `ActiveSupport::TimeZone.all.map(&:tzinfo).map(&:name)` for IANA names; validate against same list. |
| BMI/weight out of sync on direct user updates | Low | High | Only update `current_weight_kg`/`current_bmi` via `WeightLog` creation (service object); never directly. |
| JS timezone detection unavailable (old browser) | Low | Low | Fall back to empty field with `UTC` pre-selected; user must pick. |

---

<implementation_plan>
<task_name>phase-1-foundation-auth</task_name>
<task_type>Feature</task_type>
<status>complete</status>
<classification_rules>
  Feature: All steps are test-first (Red → Green → Refactor). No production code written before a failing test.
</classification_rules>

<steps>

  <step id="1" title="Bootstrap Rails 8 project" status="complete">
    <action>Run `rails new . --database=sqlite3 --skip-test` from `c:\Proyectos\moonloop`.</action>
    <action>Add to `Gemfile` (development + test group): `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`.</action>
    <action>Run `bundle install`.</action>
    <action>Run `rails generate rspec:install`.</action>
    <action>Configure `spec/rails_helper.rb` to include `FactoryBot::Syntax::Methods` and `Shoulda::Matchers` config block targeting RSpec + Rails.</action>
    <action>Verify `rails server` boots and `rspec` runs with 0 examples, 0 failures.</action>
  </step>

  <step id="2" title="Install authentication-zero" status="complete">
    <action>Add `authentication-zero` to `Gemfile`. Run `bundle install`.</action>
    <action>Run `rails generate authentication` (no extra flags). Review generated files: `User`, `Session` models, migrations, controllers, views, mailers.</action>
    <action>Do NOT run `rails db:migrate` yet — migration will be amended in Step 3 first.</action>
  </step>

  <step id="3" title="[TDD] Extend User migration and model with profile fields" status="complete">
    <action>**RED:** Write `spec/models/user_spec.rb` with failing tests covering:
      - Validates presence of `email`, `date_of_birth`, `height_cm`, `timezone`.
      - Validates `height_cm` is in range 50–300.
      - Validates `date_of_birth` is at least 10 years ago and no more than 120 years ago.
      - Validates `timezone` is a valid IANA zone.
      - `attr_readonly :height_cm` — assigning a new value after creation does not persist.
      - `#age` returns the correct integer for today's date.
      - `current_bmi` is nil when `current_weight_kg` is nil.
    </action>
    <action>**AMEND MIGRATION:** Before running, add to the `create_users` migration: `date_of_birth` (date, null: false), `height_cm` (integer, null: false), `timezone` (string, null: false, default: ''), `current_weight_kg` (decimal, precision: 5, scale: 2), `current_bmi` (decimal, precision: 4, scale: 2).</action>
    <action>Run `rails db:migrate`.</action>
    <action>**GREEN:** Implement in `User` model: validations, `attr_readonly :height_cm`, custom `timezone` validator using `ActiveSupport::TimeZone`, `date_of_birth` range validator, and `#age` helper.</action>
    <action>**REFACTOR:** Extract validators if needed. Run `rspec spec/models/user_spec.rb` → all green.</action>
  </step>

  <step id="4" title="[TDD] WeightLog model" status="complete">
    <action>**RED:** Write `spec/models/weight_log_spec.rb` covering:
      - Belongs to `User`.
      - Validates presence of `weight_kg`, `height_cm`, `bmi`.
      - Validates `weight_kg` is in range 20–500.
      - `weight_kg` and `height_cm` values are frozen (records are append-only — tested via `attr_readonly`).
      - `#bmi` is correctly computed as `weight_kg / (height_cm / 100.0) ** 2`, rounded to 2 decimal places.
    </action>
    <action>Create migration `create_weight_logs`: `user_id` (references, null: false), `weight_kg` (decimal, precision: 5, scale: 2, null: false), `height_cm` (integer, null: false), `bmi` (decimal, precision: 4, scale: 2, null: false), `timestamps`. Add index on `[user_id, created_at]`.</action>
    <action>Run `rails db:migrate`.</action>
    <action>**GREEN:** Implement `WeightLog` model with associations, validations, `attr_readonly` for `weight_kg` and `height_cm`, and a `before_validation :compute_bmi` callback.</action>
    <action>Create `spec/factories/weight_logs.rb` and `spec/factories/users.rb`.</action>
    <action>**REFACTOR.** Run `rspec spec/models/weight_log_spec.rb` → all green.</action>
  </step>

  <step id="5" title="[TDD] WeightLog creation syncs User current stats" status="complete">
    <action>**RED:** Write `spec/services/log_weight_service_spec.rb` covering:
      - Creates a `WeightLog` record with correct `weight_kg`, `height_cm` (snapshot from user), `bmi`.
      - Updates `user.current_weight_kg` and `user.current_bmi` after creation.
      - Creating a second log for the same user on the same day is allowed (multiple entries).
      - Does NOT update user stats if the `WeightLog` is invalid.
    </action>
    <action>**GREEN:** Implement `app/services/log_weight_service.rb`:
      ```ruby
      class LogWeightService
        def initialize(user, weight_kg)
          @user = user
          @weight_kg = weight_kg
        end

        def call
          log = @user.weight_logs.build(weight_kg: @weight_kg, height_cm: @user.height_cm)
          if log.save
            @user.update_columns(current_weight_kg: log.weight_kg, current_bmi: log.bmi)
            { success: true, log: log }
          else
            { success: false, errors: log.errors }
          end
        end
      end
      ```
    </action>
    <action>**REFACTOR.** Run `rspec spec/services/` → all green.</action>
  </step>

  <step id="6" title="[TDD] Signup form with profile fields + timezone Stimulus controller" status="complete">
    <action>**RED:** Write `spec/system/registration_spec.rb` (Capybara + RSpec system tests) covering:
      - User can fill out and submit the signup form with all fields.
      - Submitting with missing `height_cm` or `date_of_birth` shows validation errors.
      - Submitting with invalid timezone shows validation error.
      - After successful signup, user is redirected to root path and is logged in.
      - Timezone field is pre-populated by JS on page load (test with mocked Stimulus).
    </action>
    <action>**GREEN:** Extend `RegistrationsController` (or wherever authentication-zero puts signup) to permit: `date_of_birth`, `height_cm`, `timezone`.
      - Add the profile fields to the registration form view.
      - Add a `timezone` select using `time_zone_select` helper (mapping IANA zones).
      - Create `app/javascript/controllers/timezone_controller.js` (Stimulus): on `connect`, read `Intl.DateTimeFormat().resolvedOptions().timeZone`, set the select value if it matches a valid IANA zone.
      - Register the controller in `application.js`.
    </action>
    <action>**REFACTOR.** Run `rspec spec/system/` → all green.</action>
  </step>

  <step id="7" title="[TDD] Profile edit (all fields except height)" status="complete">
    <action>**RED:** Write `spec/system/profile_spec.rb` covering:
      - Authenticated user can edit `date_of_birth`, `timezone`, `email`.
      - `height_cm` field is NOT present in the edit form.
      - Attempting to PATCH `height_cm` via form manipulation does not change its value.
      - Unauthenticated user is redirected to login.
    </action>
    <action>**GREEN:** Create `ProfilesController` with `edit` and `update` actions.
      - Permit only: `date_of_birth`, `timezone`, `email`.
      - Profile edit view renders current values, shows timezone select with current value pre-selected.
      - Add routes: `resource :profile, only: [:edit, :update]`.
    </action>
    <action>**REFACTOR.** Run `rspec spec/system/profile_spec.rb` → all green.</action>
  </step>

  <step id="8" title="Update ROADMAP.md" status="complete">
    <action>Update Phase 6 items #23–24 to mention BMI tracking explicitly:
      - #23: `Weight log: record entries over time (date+time, weight_kg, height_cm snapshot, bmi) — Depends on: Phase 1`
      - #24: `Weight + BMI history view showing progression over time — Depends on: #23`
    </action>
    <action>No test needed for a doc update.</action>
  </step>

  <step id="9" title="Full test suite green baseline" status="complete">
    <action>Run `rspec --format documentation`.</action>
    <action>All examples must pass. Zero pending or failing.</action>
    <action>Run `rails db:migrate RAILS_ENV=test` to ensure test schema is current.</action>
  </step>

</steps>

<verification_checklist>
  - [ ] `rails new` was run with `--skip-test`
  - [ ] RSpec, FactoryBot, Shoulda-Matchers configured
  - [ ] authentication-zero installed (email + password, no extra flags)
  - [ ] `users` table has: `date_of_birth`, `height_cm`, `timezone`, `current_weight_kg`, `current_bmi`
  - [ ] `height_cm` is `attr_readonly` on `User`
  - [ ] `weight_logs` table exists with: `user_id`, `weight_kg`, `height_cm`, `bmi`, `timestamps`
  - [ ] `LogWeightService` syncs `current_weight_kg` and `current_bmi` on `User`
  - [ ] Timezone Stimulus controller pre-fills signup form from browser
  - [ ] Profile edit excludes `height_cm`
  - [ ] ROADMAP.md items #23–24 updated
  - [ ] Full RSpec suite: green, zero failures
</verification_checklist>
</implementation_plan>
