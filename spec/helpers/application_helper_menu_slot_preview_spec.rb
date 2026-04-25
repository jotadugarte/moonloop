# frozen_string_literal: true

require "rails_helper"

# [REQ-MENU-002] — Menu slot previews must use the canonical thumb variant mapping (ROADMAP #53, plan step 4).
RSpec.describe ApplicationHelper, type: :helper do
  describe "#menu_slot_preview_image_tag" do
    # [REQ-MENU-002]
    it "uses ImageVariants::ResizeToLimit.for(:thumb) instead of an ad-hoc array" do
      uploaded_image = double("uploaded image")
      preview = double("preview", display: :uploaded, uploaded_image: uploaded_image)

      allow(helper).to receive(:t).and_return("alt")
      allow(helper).to receive(:image_tag).and_return("<img>")
      allow(helper).to receive(:attachable_image_tag).and_return("<img>")

      helper.menu_slot_preview_image_tag(preview, :desayuno)

      expect(helper).to have_received(:attachable_image_tag).with(
        uploaded_image,
        hash_including(resize_to_limit: ImageVariants::ResizeToLimit.for(:thumb))
      )
    end
  end
end
