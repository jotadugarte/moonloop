# frozen_string_literal: true

require "rails_helper"

RSpec.describe Phases::ApplyAdoptionSourceSync do
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  # [REQ-CAT-001] — phases adoption sync apply (REQ-ID finalized in SPEC step S11 of task plan)
  it "raises not_adopted_copy when there is no adoption metadata" do
    phase = Phase.create!(user: adopter, name: "X", weeks_total: 4, publicly_shareable: false)

    expect do
      described_class.call(copy: phase)
    end.to raise_error(described_class::Error) { |e| expect(e.key).to eq(:not_adopted_copy) }
  end

  # [REQ-CAT-001] — phases adoption sync apply (REQ-ID finalized in SPEC step S11 of task plan)
  it "updates the copy when the source template changed and expected fingerprint matches" do
    source = Phase.create!(user: author, name: "Src", weeks_total: 4, publicly_shareable: true)
    copy = Phases::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Copia")
    old_fp = copy.source_sync_fingerprint

    source.update!(weeks_total: 6)
    expected = Phases::ContentFingerprint.for_phase(source.reload)

    described_class.call(copy: copy.reload, expected_origin_fingerprint: expected)

    copy.reload
    expect(copy.weeks_total).to eq(6)
    expect(copy.source_sync_fingerprint).to eq(expected)
    expect(copy.source_sync_fingerprint).not_to eq(old_fp)
  end

  # [REQ-CAT-001] — phases adoption sync apply (REQ-ID finalized in SPEC step S11 of task plan)
  it "raises origin_changed_retry when expected fingerprint does not match the current origin fingerprint" do
    source = Phase.create!(user: author, name: "Src", weeks_total: 4, publicly_shareable: true)
    copy = Phases::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Copia")

    source.update!(weeks_total: 6)
    current = Phases::ContentFingerprint.for_phase(source.reload)

    expect do
      described_class.call(copy: copy.reload, expected_origin_fingerprint: "#{current}x")
    end.to raise_error(described_class::Error) { |e| expect(e.key).to eq(:origin_changed_retry) }
  end

  # [REQ-CAT-001] — phases adoption sync apply (REQ-ID finalized in SPEC step S11 of task plan)
  it "raises source_unavailable when the source is no longer public" do
    source = Phase.create!(user: author, name: "Src", weeks_total: 4, publicly_shareable: true)
    copy = Phases::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Copia")
    source.update!(publicly_shareable: false)

    expect do
      described_class.call(copy: copy.reload)
    end.to raise_error(described_class::Error) { |e| expect(e.key).to eq(:source_unavailable) }
  end
end
