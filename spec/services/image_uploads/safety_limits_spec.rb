# frozen_string_literal: true

require "rails_helper"

# [REQ-MENU-002] — Uploads must enforce hard safety limits (ROADMAP #53, plan step 6).
RSpec.describe ImageUploads::SafetyLimits do
  describe ".validate" do
    # [REQ-MENU-002]
    it "rejects blobs larger than 25MB" do
      blob = instance_double("ActiveStorage::Blob", byte_size: 25.megabytes + 1, metadata: {})

      result = described_class.validate(blob)

      expect(result).to be_rejected
      expect(result.errors).to include(:too_large)
    end

    # [REQ-MENU-002]
    it "rejects blobs with a longest side larger than 8000px" do
      blob = instance_double(
        "ActiveStorage::Blob",
        byte_size: 1234,
        metadata: { "width" => 8001, "height" => 1 }
      )

      result = described_class.validate(blob)

      expect(result).to be_rejected
      expect(result.errors).to include(:too_many_pixels)
    end
  end
end

