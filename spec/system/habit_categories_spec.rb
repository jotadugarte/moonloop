require "rails_helper"
require "action_view/record_identifier"

# REQ-HABITS-007: Users can manage categories (create, rename, delete) with deletion blocked when referenced.
RSpec.describe "Habit categories", type: :system do
  include ActionView::RecordIdentifier
  let(:user) { create(:user, password: "Password123!") }

  before do
    driven_by(:rack_test)

    visit sign_in_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Password123!"
    click_button "Sign in"
  end

  it "allows creating and renaming a category" do
    visit habit_categories_path

    fill_in "Name", with: "Alimentación"
    click_button "Create Category"

    expect(page).to have_content("Alimentación")

    click_link "Edit", match: :first
    fill_in "Name", with: "Nutrición"
    click_button "Update Category"

    expect(page).to have_content("Nutrición")
  end

  it "blocks deletion when category has habits" do
    category = HabitCategory.create!(user: user, name: "Salud Física", name_normalized: "salud física")
    UserHabit.create!(
      user: user,
      habit_category: category,
      name: "Agua",
      name_normalized: "agua",
      active: true
    )

    visit habit_categories_path

    within("##{dom_id(category)}") do
      click_button "Delete"
    end

    expect(page).to have_content("cannot delete")
    expect(page).to have_content("Salud Física")
  end

  it "allows deleting an empty category" do
    HabitCategory.create!(user: user, name: "Emocional", name_normalized: "emocional")

    visit habit_categories_path
    click_button "Delete", match: :first

    expect(page).not_to have_content("Emocional")
  end
end

