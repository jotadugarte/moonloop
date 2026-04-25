# frozen_string_literal: true

require "rails_helper"

# [REQ-MENU-002] — System architecture must link to the canonical images rule doc (ROADMAP #53, plan step 2).
RSpec.describe "docs/core/SYSTEM_ARCHITECTURE images rule link (REQ-MENU-002)", :aggregate_failures do
  let(:architecture_path) { Rails.root.join("docs/core/SYSTEM_ARCHITECTURE.md") }
  let(:body) { architecture_path.read }

  it "references docs/core/IMAGES.md as the source of truth for image upload/render rules" do
    expect(body).to include("docs/core/IMAGES.md")
  end
end
