# frozen_string_literal: true

require "rails_helper"

RSpec.describe Phases::AdoptionSyncStatus do
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  # [REQ-CAT-001] — phases adoption sync (REQ-ID finalized in SPEC step S11 of task plan)
  it "returns none when the phase is not an adopted copy" do
    phase = Phase.create!(user: adopter, name: "Local", weeks_total: 4, publicly_shareable: false)

    expect(described_class.for_phase(phase).key).to eq(:none)
  end

  # [REQ-CAT-001] — phases adoption sync (REQ-ID finalized in SPEC step S11 of task plan)
  it "returns unavailable when the source is no longer public" do
    source = Phase.create!(user: author, name: "Src", weeks_total: 4, publicly_shareable: true)
    copy = Phases::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Copia")

    source.update!(publicly_shareable: false)

    expect(described_class.for_phase(copy.reload).key).to eq(:unavailable)
  end

  # [REQ-CAT-001] — phases adoption sync (REQ-ID finalized in SPEC step S11 of task plan)
  it "returns pending when the source template fingerprint drifts" do
    source = Phase.create!(user: author, name: "Src", weeks_total: 4, publicly_shareable: true)
    copy = Phases::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Copia")

    source.update!(weeks_total: 6)

    st = described_class.for_phase(copy.reload)
    expect(st.key).to eq(:pending)
    expect(st.origin_fingerprint).to eq(Phases::ContentFingerprint.for_phase(source.reload))
  end
end
