# frozen_string_literal: true

require "stringio"
require "uri"

require "rails_helper"

RSpec.describe "Recipes CRUD", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-MENU-002]
  it "lists the signed-in user's recipes" do
    Recipe.create!(user: user, name: "Avena")
    Recipe.create!(user: create(:user, password: "Password123!"), name: "Ajena")

    get recipes_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Avena")
    expect(response.body).not_to include("Ajena")
  end

  # [REQ-MENU-002]
  it "creates a recipe with instructions and optional image" do
    image_path = Rails.root.join("spec/fixtures/files/recipe_test.svg")

    post recipes_path,
      params: {
        recipe: {
          name: "Ensalada",
          instructions: "Mezclar todo.",
          meal_type: "cena",
          publicly_shareable: "1",
          image: Rack::Test::UploadedFile.new(image_path, "image/svg+xml")
        }
      }

    expect(response).to have_http_status(:found)
    recipe = Recipe.find_by!(user: user, name: "Ensalada")
    expect(recipe.instructions).to include("Mezclar")
    expect(recipe.publicly_shareable).to eq(true)
    expect(recipe.image).to be_attached
  end

  # [REQ-MENU-002]
  it "attaches a meal-type placeholder image when creating a recipe without an upload" do
    post recipes_path,
      params: {
        recipe: {
          name: "Avena",
          instructions: "",
          publicly_shareable: "0",
          meal_type: "desayuno"
        }
      }

    expect(response).to have_http_status(:found)
    recipe = Recipe.find_by!(user: user, name: "Avena")
    expect(recipe.image).to be_attached
    expect(recipe.image.filename.to_s).to include("fallback_desayuno")
  end

  # [REQ-MENU-002]
  it "forbids accessing another user's recipe" do
    other = create(:user, password: "Password123!", timezone: "Etc/UTC")
    foreign = Recipe.create!(user: other, name: "Ajena")

    get recipe_path(foreign)

    expect(response).to have_http_status(:not_found)
  end

  # [REQ-MENU-002]
  it "serves a successful raster image when the recipe show page links a PNG hero" do
    png_path = Rails.root.join("spec/fixtures/files/recipe_test_1x1.png")
    recipe = Recipe.create!(user: user, name: "Plato raster")
    recipe.image.attach(
      io: StringIO.new(File.binread(png_path)),
      filename: "hero.png",
      content_type: "image/png"
    )

    get recipe_path(recipe)
    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    img = doc.at_css("img[alt='Plato raster']")
    expect(img).to be_present
    src = img["src"]
    expect(src).to be_present

    path = src.start_with?("http") ? URI(src).request_uri : src
    get path
    6.times do
      break unless response.redirect?

      follow_redirect!
    end
    expect(response).to have_http_status(:ok)
    expect(response.body.bytesize).to be_positive
    expect(response.content_type.to_s).to match(/\Aimage\//)
  end

  # [REQ-MENU-002]
  it "updates a recipe and can remove the image when requested" do
    recipe = Recipe.create!(user: user, name: "Sopa")
    recipe.image.attach(
      io: StringIO.new(File.read(Rails.root.join("spec/fixtures/files/recipe_test.svg"))),
      filename: "recipe_test.svg",
      content_type: "image/svg+xml"
    )

    patch recipe_path(recipe),
      params: {
        recipe: {
          name: "Sopa fría",
          instructions: "",
          publicly_shareable: "0",
          remove_image: "1"
        }
      }

    expect(response).to have_http_status(:found)
    recipe.reload
    expect(recipe.name).to eq("Sopa fría")
    expect(recipe.image).to be_attached
    expect(recipe.image.filename.to_s).to include("fallback_")
  end

  # [REQ-MENU-002]
  it "destroys a recipe and removes menu entries that referenced it" do
    menu = Menu.create!(user: user, name: "Semana")
    recipe = Recipe.create!(user: user, name: "Pasta")
    entry = MenuEntry.create!(
      menu: menu,
      recipe: recipe,
      weekday: 1,
      meal_type: "cena",
      freeform_text: nil
    )

    delete recipe_path(recipe)

    expect(response).to have_http_status(:found)
    expect(Recipe.find_by(id: recipe.id)).to be_nil
    expect(MenuEntry.find_by(id: entry.id)).to be_nil
  end
end
