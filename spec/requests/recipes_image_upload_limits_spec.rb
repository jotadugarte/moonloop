# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recipe image upload safety limits", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-MENU-002]
  it "returns 422 and shows an i18n error when the image is rejected by safety limits" do
    image_path = Rails.root.join("spec/fixtures/files/recipe_test_1x1.png")

    rejected = ImageUploads::SafetyLimits::Result.new(errors: [ :too_large ])
    allow(ImageUploads::SafetyLimits).to receive(:validate).and_return(rejected)

    post recipes_path,
      params: {
        recipe: {
          name: "Límite",
          instructions: "",
          meal_type: "cena",
          publicly_shareable: "0",
          image: Rack::Test::UploadedFile.new(image_path, "image/png")
        }
      }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include(I18n.t("activerecord.errors.models.recipe.attributes.image.too_large"))
  end
end

