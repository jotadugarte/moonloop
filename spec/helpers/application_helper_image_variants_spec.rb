# frozen_string_literal: true

require "rails_helper"

# [REQ-MENU-002] — UI image rendering must use the standardized WebP variant options (ROADMAP #53, plan step 4).
RSpec.describe ApplicationHelper, type: :helper do
  describe "#attachable_image_tag" do
    # [REQ-MENU-002]
    it "uses ImageVariants::VariantOptions (WebP) when variants are available" do
      blob = instance_double("ActiveStorage::Blob", content_type: "image/jpeg")
      attachment = double("ActiveStorage attachment", blob: blob)

      allow(attachment).to receive(:variable?).and_return(true)
      allow(ImageVariants::Available).to receive(:call).and_return(true)
      allow(attachment).to receive(:variant).and_return("variant-ref")
      allow(helper).to receive(:image_tag).and_return("<img>")

      helper.attachable_image_tag(attachment, resize_to_limit: ImageVariants::ResizeToLimit.for(:thumb), alt: "x")

      expect(attachment).to have_received(:variant).with(hash_including(format: :webp))
    end
  end
end

