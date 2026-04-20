# frozen_string_literal: true

require "rails_helper"

RSpec.describe PhaseProgram, type: :model do
  let(:user) { create(:user) }

  # [REQ-PHS-001]
  it "belongs to a user" do
    program = described_class.new(name: "Plan integrado", user: user)
    expect(program.user).to eq(user)
  end

  # [REQ-PHS-001]
  it "requires a non-blank name" do
    program = described_class.new(user: user, name: "   ")
    expect(program).not_to be_valid
    expect(program.errors[:name]).to be_present
  end

  # [REQ-PHS-001]
  it "normalizes name by stripping whitespace" do
    program = described_class.new(user: user, name: "  Verano  ")
    program.valid?
    expect(program.name).to eq("Verano")
  end

  # [REQ-PHS-001]
  it "persists publicly_shareable defaulting to false" do
    program = described_class.create!(user: user, name: "Único")
    expect(program.reload.publicly_shareable).to eq(false)
  end

  # [REQ-PHS-001]
  it "reflects optional source_phase_program and adopted_copies for catalog adoption parity" do
    src = described_class.reflect_on_association(:source_phase_program)
    expect(src.options[:class_name]).to eq("PhaseProgram")
    expect(src.options[:optional]).to eq(true)

    copies = described_class.reflect_on_association(:adopted_copies)
    expect(copies.klass).to eq(described_class)
    expect(copies.options[:dependent]).to eq(:nullify)
  end

  # [REQ-PHS-001]
  it "stores adoption_catalog_origin_id and source_sync_fingerprint when set" do
    owner = create(:user)
    template = described_class.create!(
      user: owner,
      name: "Plantilla",
      publicly_shareable: true
    )
    adopter = create(:user)
    copy = described_class.create!(
      user: adopter,
      name: "Copia",
      source_phase_program: template,
      adoption_catalog_origin_id: template.id,
      source_sync_fingerprint: "fp-test"
    )
    copy.reload
    expect(copy.adoption_catalog_origin_id).to eq(template.id)
    expect(copy.source_sync_fingerprint).to eq("fp-test")
    expect(copy.source_phase_program).to eq(template)
  end
end
