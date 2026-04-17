# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin moderation of public sharing", type: :request do
  around do |example|
    previous = ENV["MOONLOOP_ADMIN_EMAILS"]
    example.run
  ensure
    if previous.nil?
      ENV.delete("MOONLOOP_ADMIN_EMAILS")
    else
      ENV["MOONLOOP_ADMIN_EMAILS"] = previous
    end
  end

  # [REQ-MENU-002]
  it "allows an admin to revoke public sharing on a recipe" do
    admin = create(:user, email: "admin@example.com", password: "Password123!", timezone: "Etc/UTC")
    author = create(:user, password: "Password123!", timezone: "Etc/UTC")
    recipe = Recipe.create!(user: author, name: "Spam publicada", publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = admin.email

    post sign_in_path, params: { email: admin.email, password: "Password123!" }

    patch "/admin/recipes/#{recipe.id}/revoke_public_share"

    expect(response).to have_http_status(:found)
    expect(recipe.reload.publicly_shareable).to eq(false)
  end

  # [REQ-MENU-002]
  it "hides a revoked recipe from the public catalog" do
    admin = create(:user, email: "admin@example.com", password: "Password123!", timezone: "Etc/UTC")
    author = create(:user, password: "Password123!", timezone: "Etc/UTC")
    recipe = Recipe.create!(user: author, name: "Spam publicada", publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = admin.email

    post sign_in_path, params: { email: admin.email, password: "Password123!" }
    patch "/admin/recipes/#{recipe.id}/revoke_public_share"
    follow_redirect! if response.redirect?

    get public_recipes_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Spam publicada")
  end

  # [REQ-MENU-002]
  it "rejects moderation actions for non-admin users" do
    viewer = create(:user, email: "viewer@example.com", password: "Password123!", timezone: "Etc/UTC")
    author = create(:user, password: "Password123!", timezone: "Etc/UTC")
    recipe = Recipe.create!(user: author, name: "No tocar", publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = "admin@example.com"

    post sign_in_path, params: { email: viewer.email, password: "Password123!" }

    patch "/admin/recipes/#{recipe.id}/revoke_public_share"

    expect(response).to have_http_status(:forbidden)
    expect(recipe.reload.publicly_shareable).to eq(true)
  end

  # [REQ-MENU-001]
  it "allows an admin to revoke public sharing on a menu" do
    admin = create(:user, email: "admin@example.com", password: "Password123!", timezone: "Etc/UTC")
    owner = create(:user, password: "Password123!", timezone: "Etc/UTC")
    menu = Menu.create!(user: owner, name: "Menú spam", publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = admin.email

    post sign_in_path, params: { email: admin.email, password: "Password123!" }

    patch "/admin/menus/#{menu.id}/revoke_public_share"

    expect(response).to have_http_status(:found)
    expect(menu.reload.publicly_shareable).to eq(false)
  end
end
