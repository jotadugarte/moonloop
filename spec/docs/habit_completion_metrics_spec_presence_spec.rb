# frozen_string_literal: true

require "rails_helper"

# [REQ-DAY-005] — SPEC must document habit metrics before implementation (start-task plan step 1).
RSpec.describe "docs/core/SPEC habit completion metrics", :aggregate_failures do
  let(:spec_path) { Rails.root.join("docs/core/SPEC.md") }
  let(:body) { spec_path.read }

  it "includes REQ-DAY-005 and glossary entries for metric kind, daily target, and day progress" do
    expect(body).to include("REQ-DAY-005")
    expect(body).to match(/\| Habit metric kind \|/)
    expect(body).to match(/\| Daily target \(habit\) \|/)
    expect(body).to match(/\| Day progress \(habit completion\) \|/)
  end
end
