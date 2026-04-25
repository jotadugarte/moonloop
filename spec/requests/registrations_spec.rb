# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Registrations", type: :request do
  # [REQ-PROF-003]
  it "serves initial sign-up HTML with imperial height wrappers hidden when units default to metric" do
    get sign_up_path

    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    metric = doc.at_css('[data-unit-system-toggle-target="metric"]')
    imperial = doc.css('[data-unit-system-toggle-target="imperial"]')
    expect(metric["class"].to_s.split).not_to include("hidden")
    expect(imperial.size).to eq(2)
    imperial.each { |node| expect(node["class"]).to include("hidden") }
  end

  # [REQ-PROF-003]
  it "422 re-render hides metric height wrapper when imperial units are selected" do
    post sign_up_path, params: {
      user: {
        email: "imperial_rerender@example.com",
        password: "",
        password_confirmation: "",
        birth_year: "1990",
        birth_month: "5",
        birth_day: "15",
        timezone: "America/Santiago",
        body_unit_system: "imperial_us",
        height_feet: "5",
        height_inches: "7"
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    doc = Nokogiri::HTML(response.body)
    metric = doc.at_css('[data-unit-system-toggle-target="metric"]')
    imperial = doc.css('[data-unit-system-toggle-target="imperial"]')
    expect(metric["class"]).to include("hidden")
    expect(imperial.size).to eq(2)
    imperial.each do |node|
      expect(node["class"].to_s.split).not_to include("hidden")
    end
  end
end
