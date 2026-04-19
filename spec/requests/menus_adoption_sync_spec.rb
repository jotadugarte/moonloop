# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Menu adoption sync", type: :request do
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def sign_in!(user)
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  def create_public_menu(user:, name:, publicly_shareable: true)
    Menu.create!(user: user, name: name, publicly_shareable: publicly_shareable)
  end

  def adopt!(adopter:, origin:, name: "Mi copia menú")
    sign_in!(adopter)
    post adopt_public_menu_path(origin), params: { name: name }
    Menu.find_by!(user: adopter, name: name)
  end

  # [REQ-MENU-006]
  it "shows pending adoption sync on edit when the source content changed" do
    origin = create_public_menu(user: author, name: "Origin")
    MenuEntry.create!(menu: origin, weekday: 2, meal_type: "cena", freeform_text: "Ensalada")
    copy = adopt!(adopter: adopter, origin: origin, name: "Mantener nombre")

    origin.menu_entries.first.update!(freeform_text: "Ensalada revisada")

    get edit_menu_path(copy)

    expect(response.body).to include(I18n.t("menus.edit.adoption_sync.pending"))
  end

  # [REQ-MENU-006]
  it "applies source entries and keeps copy name and phase assignments" do
    origin = create_public_menu(user: author, name: "O")
    MenuEntry.create!(menu: origin, weekday: 1, meal_type: "almuerzo", freeform_text: "Old")
    copy = adopt!(adopter: adopter, origin: origin, name: "Nombre copia")
    PhaseAssignment.create!(user: adopter, menu: copy, start_week: 1, end_week: 3)
    assignment_id = copy.phase_assignments.sole.id

    origin.menu_entries.first.update!(freeform_text: "New note")

    fp = Menus::ContentFingerprint.for_menu(origin.reload)
    post accept_source_update_menu_path(copy), params: { expected_origin_fingerprint: fp }

    expect(response).to redirect_to(edit_menu_path(copy))
    copy.reload
    expect(copy.name).to eq("Nombre copia")
    expect(copy.menu_entries.sole.freeform_text).to include("New note")
    expect(copy.phase_assignments.sole.id).to eq(assignment_id)
  end

  # [REQ-MENU-006]
  it "rejects apply when the source changed again after the form was rendered" do
    origin = create_public_menu(user: author, name: "O")
    MenuEntry.create!(menu: origin, weekday: 0, meal_type: "cena", freeform_text: "V1")
    copy = adopt!(adopter: adopter, origin: origin)
    origin.menu_entries.first.update!(freeform_text: "V2")
    fp_at_render = Menus::ContentFingerprint.for_menu(origin.reload)
    origin.menu_entries.first.update!(freeform_text: "V3")

    post accept_source_update_menu_path(copy), params: { expected_origin_fingerprint: fp_at_render }

    expect(response).to redirect_to(edit_menu_path(copy))
    expect(flash[:alert]).to eq(I18n.t("menus.adoption_sync.errors.origin_changed_retry"))
    copy.reload
    expect(copy.menu_entries.sole.freeform_text).to include("V1")
  end

  # [REQ-MENU-006]
  it "shows unavailable on edit when the source was deleted" do
    origin = create_public_menu(user: author, name: "Gone")
    MenuEntry.create!(menu: origin, weekday: 0, meal_type: "cena", freeform_text: "x")
    copy = adopt!(adopter: adopter, origin: origin)
    origin.destroy!

    get edit_menu_path(copy.reload)

    expect(response.body).to include(I18n.t("menus.edit.adoption_sync.unavailable"))
  end

  # [REQ-MENU-006]
  it "shows unavailable when the source is no longer public" do
    origin = create_public_menu(user: author, name: "Priv")
    MenuEntry.create!(menu: origin, weekday: 3, meal_type: "merienda", freeform_text: "y")
    copy = adopt!(adopter: adopter, origin: origin)
    origin.update!(publicly_shareable: false)

    get edit_menu_path(copy.reload)

    expect(response.body).to include(I18n.t("menus.edit.adoption_sync.unavailable"))
  end
end
