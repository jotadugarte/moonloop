# frozen_string_literal: true

require "rails_helper"

# [REQ-MENU-002] — Images upload rule must be documented (ROADMAP #53, plan step 1).
RSpec.describe "docs/core/IMAGES upload pipeline rule (REQ-MENU-002)", :aggregate_failures do
  let(:images_doc_path) { Rails.root.join("docs/core/IMAGES.md") }
  let(:body) { images_doc_path.read }

  it "documents the canonical variants, format, targets, and safety limits" do
    expect(body).to include("WebP")
    expect(body).to match(/\bthumb\b/i)
    expect(body).to match(/\blist\b/i)
    expect(body).to match(/\bdetail\b/i)

    expect(body).to match(/\b160\b/)
    expect(body).to match(/\b640(px)?\b/i)
    expect(body).to match(/\b1200(px)?\b/i)

    expect(body).to match(/\b20KB\b/i)
    expect(body).to match(/\b120KB\b/i)
    expect(body).to match(/\b300KB\b/i)

    expect(body).to match(/\b25MB\b/i)
    expect(body).to match(/\b8000(px)?\b/i)
  end
end

