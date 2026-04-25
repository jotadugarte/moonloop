# frozen_string_literal: true

require "rails_helper"

# [REQ-MENU-002] — The app must expose a single, standardized variant size mapping (ROADMAP #53, plan step 3).
RSpec.describe ImageVariants::ResizeToLimit do
  describe ".for" do
    # [REQ-MENU-002]
    it "maps named UI variants to canonical resize_to_limit values" do
      expect(described_class.for(:thumb)).to eq([ 160, 160 ])
      expect(described_class.for(:list)).to eq([ 640, 640 ])
      expect(described_class.for(:detail)).to eq([ 1200, 1200 ])
    end

    # [REQ-MENU-002]
    it "rejects unknown variants" do
      expect { described_class.for(:unknown) }.to raise_error(ArgumentError)
    end
  end
end

