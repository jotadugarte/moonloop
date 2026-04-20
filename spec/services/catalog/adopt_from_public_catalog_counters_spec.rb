# frozen_string_literal: true

require "rails_helper"

RSpec.describe "AdoptFromPublicCatalog increments template counters [REQ-CAT-001]", :aggregate_failures do
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:other) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def routine_with_line(user, name)
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Move")
    r.save!
    r
  end

  # [REQ-CAT-001]
  it "increments both counters on the public menu template after a successful adoption" do
    source = Menu.create!(user: author, name: "Catálogo menú", publicly_shareable: true)
    MenuEntry.create!(menu: source, weekday: 0, meal_type: "cena", freeform_text: "x")

    Menus::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Copia menú")

    source.reload
    expect(source.public_catalog_adoptions_count).to eq(1)
    expect(source.public_catalog_distinct_adopters_count).to eq(1)
  end

  # [REQ-CAT-001]
  it "does not double counters when the same adopter retries adoption (already_adopted)" do
    source = Menu.create!(user: author, name: "Una vez", publicly_shareable: true)
    MenuEntry.create!(menu: source, weekday: 1, meal_type: "desayuno", freeform_text: "y")

    Menus::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Primera")

    expect do
      Menus::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Segunda")
    end.to raise_error(Menus::AdoptFromPublicCatalog::Error) { |e| expect(e.key).to eq(:already_adopted) }

    source.reload
    expect(source.public_catalog_adoptions_count).to eq(1)
    expect(source.public_catalog_distinct_adopters_count).to eq(1)
  end

  # [REQ-CAT-001]
  it "increments adoption count for each distinct adopter on the same menu template" do
    source = Menu.create!(user: author, name: "Popular", publicly_shareable: true)
    MenuEntry.create!(menu: source, weekday: 2, meal_type: "almuerzo", freeform_text: "z")

    Menus::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "A")
    Menus::AdoptFromPublicCatalog.call(adopter: other, source: source, chosen_name: "B")

    source.reload
    expect(source.public_catalog_adoptions_count).to eq(2)
    expect(source.public_catalog_distinct_adopters_count).to eq(2)
  end

  # [REQ-CAT-001]
  it "increments both counters on the public exercise routine template after adoption" do
    source = routine_with_line(author, "R pública")
    source.update!(publicly_shareable: true)

    ExerciseRoutines::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Copia rutina")

    source.reload
    expect(source.public_catalog_adoptions_count).to eq(1)
    expect(source.public_catalog_distinct_adopters_count).to eq(1)
  end

  # [REQ-CAT-001]
  it "increments both counters on the public phase program template after adoption" do
    menu = Menu.create!(user: author, name: "M")
    MenuEntry.create!(menu: menu, weekday: 0, meal_type: "cena", freeform_text: "soup")
    routine = routine_with_line(author, "R")
    source = PhaseProgram.create!(user: author, name: "Bundle público", publicly_shareable: true)
    PhaseProgramAssignment.create!(
      phase_program: source,
      menu: menu,
      exercise_routine: routine,
      start_week: 1,
      end_week: 2
    )

    Programs::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Copia programa")

    source.reload
    expect(source.public_catalog_adoptions_count).to eq(1)
    expect(source.public_catalog_distinct_adopters_count).to eq(1)
  end
end
