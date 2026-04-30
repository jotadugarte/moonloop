# frozen_string_literal: true

require "rails_helper"

RSpec.describe Phases::AdoptFromPublicCatalog do
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  # [REQ-CAT-001] — phases public catalog adoption (REQ-ID finalized in SPEC step S11 of task plan)
  it "copies the phase and increments adoption metrics once" do
    source = Phase.create!(user: author, name: "Fase origen", publicly_shareable: true, weeks_total: 4)
    source.update_columns(public_catalog_adoptions_count: 0, public_catalog_distinct_adopters_count: 0)

    copy = described_class.call(adopter: adopter, source: source, chosen_name: "Mi fase")

    expect(copy.user_id).to eq(adopter.id)
    expect(copy.name).to eq("Mi fase")
    expect(copy.publicly_shareable).to eq(false)
    expect(copy.source_phase_id).to eq(source.id)

    source.reload
    expect(source.public_catalog_adoptions_count).to eq(1)
    expect(source.public_catalog_distinct_adopters_count).to eq(1)
  end

  # [REQ-CAT-001] — phases public catalog adoption (REQ-ID finalized in SPEC step S11 of task plan)
  it "rejects adoption of an adopter's own phase" do
    source = Phase.create!(user: adopter, name: "Mía", publicly_shareable: true, weeks_total: 4)

    expect do
      described_class.call(adopter: adopter, source: source, chosen_name: "Copy")
    end.to raise_error(Phases::AdoptFromPublicCatalog::Error)
  end

  # [REQ-CAT-001] — phases public catalog adoption (REQ-ID finalized in SPEC step S11 of task plan)
  it "rejects a second adoption of the same origin" do
    source = Phase.create!(user: author, name: "Once", publicly_shareable: true, weeks_total: 4)

    described_class.call(adopter: adopter, source: source, chosen_name: "Primera")

    expect do
      described_class.call(adopter: adopter, source: source, chosen_name: "Segunda")
    end.to raise_error(Phases::AdoptFromPublicCatalog::Error)
  end

  # [REQ-CAT-001] — phases public catalog adoption (REQ-ID finalized in SPEC step S11 of task plan)
  it "rejects blank chosen names" do
    source = Phase.create!(user: author, name: "Origen", publicly_shareable: true, weeks_total: 4)

    expect do
      described_class.call(adopter: adopter, source: source, chosen_name: "  ")
    end.to raise_error(Phases::AdoptFromPublicCatalog::Error)
  end
end
