# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public dishes catalog (index)", type: :request do
  let(:viewer) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: viewer.email, password: "Password123!" }
  end

  # [REQ-MENU-002]
  it "lists dishes that are publicly shareable" do
    Dish.create!(user: author, name: "Pública", publicly_shareable: true)
    Dish.create!(user: author, name: "Privada", publicly_shareable: false)

    get public_dishes_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Pública")
    expect(response.body).not_to include("Privada")
  end
end
