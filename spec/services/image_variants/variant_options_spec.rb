# frozen_string_literal: true

require "rails_helper"

# [REQ-MENU-002] — Standard variants must be served as WebP with canonical sizes (ROADMAP #53, plan step 4).
RSpec.describe ImageVariants::VariantOptions do
  describe ".for" do
    # [REQ-MENU-002]
    it "returns WebP variant options for each standard variant name" do
      thumb = described_class.for(:thumb)
      list = described_class.for(:list)
      detail = described_class.for(:detail)

      expect(thumb).to include(format: :webp, resize_to_limit: ImageVariants::ResizeToLimit.for(:thumb))
      expect(list).to include(format: :webp, resize_to_limit: ImageVariants::ResizeToLimit.for(:list))
      expect(detail).to include(format: :webp, resize_to_limit: ImageVariants::ResizeToLimit.for(:detail))
    end
  end
end
