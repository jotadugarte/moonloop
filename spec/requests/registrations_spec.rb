# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Registrations", type: :request do
  # [REQ-PROF-003]
  it "serves initial sign-up HTML with imperial height wrappers hidden when units default to metric" do
    get sign_up_path

    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    metric_height = doc.at_css('[data-test="registration-height-metric"]')
    imperial_feet = doc.at_css('[data-test="registration-height-imperial-feet"]')
    imperial_inches = doc.at_css('[data-test="registration-height-imperial-inches"]')
    expect(metric_height["class"].to_s.split).not_to include("hidden")
    expect(imperial_feet["class"].to_s.split).to include("hidden")
    expect(imperial_inches["class"].to_s.split).to include("hidden")
  end

  # [REQ-PROF-002, REQ-WGT-002]
  it "allows sign-up when weight is blank and persists nil current weight and BMI" do
    post sign_up_path, params: {
      user: {
        email: "blank_weight@example.com",
        password: "password-123",
        password_confirmation: "password-123",
        birth_year: "1990",
        birth_month: "5",
        birth_day: "15",
        timezone: "America/Santiago",
        body_unit_system: "metric",
        height_cm: "170",
        weight_kg: ""
      }
    }

    expect(response).to have_http_status(:found)

    user = User.find_by(email: "blank_weight@example.com")
    expect(user).to be_present
    expect(user.current_weight_kg).to be_nil
    expect(user.current_bmi).to be_nil
  end

  # [REQ-I18N-001, REQ-WGT-002]
  it "shows a weight field with an 'optional' hint on the sign-up page" do
    get sign_up_path

    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)

    weight_input = doc.at_css('input[name="user[weight_kg]"], input[name="user[weight_lb]"]')
    expect(weight_input).to be_present

    hint = doc.at_css('[data-test="registration-weight-optional-hint"]')
    expect(hint).to be_present
    expected = I18n.t("registrations.new.weight_optional_hint", locale: I18n.default_locale)
    expect(hint.text.strip).to eq(expected)
  end

  # [REQ-PROF-002, REQ-WGT-002]
  it "does not allow sign-up with an out-of-domain weight" do
    post sign_up_path, params: {
      user: {
        email: "bad_weight@example.com",
        password: "password-123",
        password_confirmation: "password-123",
        birth_year: "1990",
        birth_month: "5",
        birth_day: "15",
        timezone: "America/Santiago",
        body_unit_system: "metric",
        height_cm: "170",
        weight_kg: "10"
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(User.find_by(email: "bad_weight@example.com")).to be_nil
    expect(response.body).to include("role=\"alert\"")
  end

  # [REQ-PROF-003, REQ-WGT-002]
  it "422 re-render shows imperial weight and hides metric weight when imperial units are selected" do
    post sign_up_path, params: {
      user: {
        email: "imperial_weight_rerender@example.com",
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

    metric_weight_wrapper = doc.at_css('[data-test="registration-weight-metric"]')
    expect(metric_weight_wrapper).to be_present
    expect(metric_weight_wrapper["class"].to_s.split).to include("hidden")

    imperial_weight_wrapper = doc.at_css('[data-test="registration-weight-imperial"]')
    expect(imperial_weight_wrapper).to be_present
    expect(imperial_weight_wrapper["class"].to_s.split).not_to include("hidden")
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
    metric_height = doc.at_css('[data-test="registration-height-metric"]')
    imperial_feet = doc.at_css('[data-test="registration-height-imperial-feet"]')
    imperial_inches = doc.at_css('[data-test="registration-height-imperial-inches"]')
    expect(metric_height["class"].to_s.split).to include("hidden")
    expect(imperial_feet["class"].to_s.split).not_to include("hidden")
    expect(imperial_inches["class"].to_s.split).not_to include("hidden")
  end
end
