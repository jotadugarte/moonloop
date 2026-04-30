# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalog::ListingFacet, type: :model do
  let(:user) { create(:user) }
  let(:menu) { Menu.create!(user: user, name: "Plan catálogo", publicly_shareable: true) }

  def routine_with_line(name: "R")
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Move")
    r.save!
    r
  end

  # [REQ-CAT-001]
  it "rejects listable_type outside allowed catalog listables" do
    facet = described_class.new(listable_type: "User", listable_id: user.id)
    expect(facet).not_to be_valid
    expect(facet.errors.of_kind?(:listable_type, :inclusion)).to eq(true)
  end

  # [REQ-CAT-001]
  it "allows at most one facet per listable (Menu)" do
    described_class.create!(listable: menu, goal_phrase: "ganancia muscular")
    dup = described_class.new(listable: menu, goal_phrase: "otro")
    expect(dup).not_to be_valid
    expect(dup.errors.of_kind?(:listable_id, :taken)).to eq(true)
  end

  # [REQ-CAT-001]
  it "rejects more than MAX_TAGS comma-separated slugs" do
    tags = (1..11).map { |i| "tag#{i}" }.join(",")
    facet = described_class.new(listable: menu, normalized_tags: tags)
    expect(facet).not_to be_valid
    expect(facet.errors[:normalized_tags].join).to include("at most #{described_class::MAX_TAGS}")
  end

  # [REQ-CAT-001]
  it "rejects a single tag longer than the slug length limit" do
    long = "a" * (described_class::MAX_TAG_SLUG_LENGTH + 1)
    facet = described_class.new(listable: menu, normalized_tags: long)
    expect(facet).not_to be_valid
    expect(facet.errors[:normalized_tags].join).to include("at most #{described_class::MAX_TAG_SLUG_LENGTH}")
  end

  # [REQ-CAT-001]
  it "rejects tag slugs that are not lowercase hyphenated identifiers" do
    facet = described_class.new(listable: menu, normalized_tags: "OK-ok,Bad Space")
    expect(facet).not_to be_valid
    expect(facet.errors[:normalized_tags].join).to include("comma-separated slugs")
  end

  # [REQ-CAT-001]
  it "accepts valid normalized tags and coerces casing" do
    facet = described_class.create!(listable: menu, normalized_tags: "Lean-Bulk, HYROX ")
    expect(facet.normalized_tags).to eq("lean-bulk,hyrox")
    expect(facet).to be_valid
  end

  # [REQ-CAT-001]
  it "rejects difficulty_level outside the closed vocabulary" do
    facet = described_class.new(listable: menu, difficulty_level: "expert")
    expect(facet).not_to be_valid
    expect(facet.errors.of_kind?(:difficulty_level, :inclusion)).to eq(true)
  end

  # [REQ-CAT-001]
  it "accepts beginner, intermediate, or advanced difficulty" do
    described_class::DIFFICULTY_LEVELS.each do |level|
      r = routine_with_line(name: "R-#{level}")
      facet = described_class.create!(listable: r, difficulty_level: level)
      expect(facet).to be_persisted
    end
  end

  # [REQ-CAT-001]
  it "rejects duration_weeks_min above duration_weeks_max when both set" do
    facet = described_class.new(listable: menu, duration_weeks_min: 4, duration_weeks_max: 2)
    expect(facet).not_to be_valid
    expect(facet.errors.of_kind?(:duration_weeks_max, :greater_than_or_equal_to)).to eq(true)
  end

  # [REQ-CAT-001]
  it "destroys the facet when the listable is destroyed" do
    facet = described_class.create!(listable: menu, goal_phrase: "x")
    expect { menu.destroy! }.to change(described_class, :count).by(-1)
    expect { facet.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
