# frozen_string_literal: true

require "rails_helper"

# [REQ-MENU-002] — When variants are unavailable, helpers must fall back to the original blob (ROADMAP #53, plan step 7).
RSpec.describe ApplicationHelper, type: :helper do
  describe "#attachable_image_tag" do
    # [REQ-MENU-002]
    it "does not request a variant when ImageVariants::Available is false" do
      blob = instance_double("ActiveStorage::Blob", content_type: "image/jpeg")
      attachment = double("ActiveStorage attachment", blob: blob)

      allow(attachment).to receive(:variable?).and_return(true)
      allow(ImageVariants::Available).to receive(:call).and_return(false)
      allow(attachment).to receive(:variant)
      allow(helper).to receive(:image_tag).and_return("<img>")

      helper.attachable_image_tag(attachment, resize_to_limit: ImageVariants::ResizeToLimit.for(:thumb), alt: "x")

      expect(attachment).not_to have_received(:variant)
    end
  end
end
