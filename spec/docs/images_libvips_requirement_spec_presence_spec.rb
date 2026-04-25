# frozen_string_literal: true

require "rails_helper"

# [REQ-MENU-002] — CI must document/install libvips so image variants are testable (ROADMAP #53, plan step 5).
RSpec.describe "CI libvips requirement for image variants (REQ-MENU-002)", :aggregate_failures do
  let(:ci_path) { Rails.root.join(".github/workflows/ci.yml") }
  let(:readme_path) { Rails.root.join("README.md") }
  let(:ci_body) { ci_path.read }
  let(:readme_body) { readme_path.read }

  it "mentions libvips in README and installs it in CI" do
    expect(readme_body).to match(/libvips|vips/i)
    expect(ci_body).to match(/apt-get.*(libvips|vips)/i)
  end
end

