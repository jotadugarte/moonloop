# Review ledger

Cleared after harvest-rules.

- **Issue:** RuboCop `Layout/TrailingEmptyLines` in new factories/support helper files.
  - **Diagnosis/Why it failed:** Files ended with an extra blank line, violating the project's RuboCop layout rules.
  - **Fix:** Removed the trailing blank line from `spec/factories/menu_entries.rb`, `spec/factories/menus.rb`, `spec/factories/recipes.rb`, and `spec/support/system/registration_helpers.rb`.
