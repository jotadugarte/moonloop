# frozen_string_literal: true

require "rails_helper"

# [REQ-CAT-001] — SPEC + schema reference must register public catalog metrics & discovery (start-task #34, plan step 1).
RSpec.describe "docs/core/SPEC + SCHEMA public catalog metrics (REQ-CAT-001)", :aggregate_failures do
  let(:spec_path) { Rails.root.join("docs/core/SPEC.md") }
  let(:schema_path) { Rails.root.join("docs/core/SCHEMA_REFERENCE.md") }
  let(:spec_body) { spec_path.read }
  let(:schema_body) { schema_path.read }

  it "registers REQ-CAT-001, the CAT domain row, and an acceptance section heading" do
    expect(spec_body).to include("REQ-CAT-001")
    expect(spec_body).to match(/\| `CAT` \|/)
    expect(spec_body).to include("#### REQ-CAT-001")
  end

  it "documents adoption counters on template tables and the catalog listing facets table in SCHEMA_REFERENCE" do
    expect(schema_body).to include("public_catalog_adoptions_count")
    expect(schema_body).to include("public_catalog_distinct_adopters_count")
    expect(schema_body).to include("catalog_listing_facets")
  end
end
