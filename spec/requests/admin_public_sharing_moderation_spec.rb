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
  it "allows an admin to revoke public sharing on a dish" do
    admin = create(:user, email: "admin@example.com", password: "Password123!", timezone: "Etc/UTC")
    author = create(:user, password: "Password123!", timezone: "Etc/UTC")
    dish = Dish.create!(user: author, name: "Spam publicada", publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = admin.email

    post sign_in_path, params: { email: admin.email, password: "Password123!" }

    patch revoke_public_share_admin_dish_path(dish)

    expect(response).to have_http_status(:found)
    expect(dish.reload.publicly_shareable).to eq(false)
  end

  # [REQ-MENU-002]
  it "hides a revoked dish from the public catalog" do
    admin = create(:user, email: "admin@example.com", password: "Password123!", timezone: "Etc/UTC")
    author = create(:user, password: "Password123!", timezone: "Etc/UTC")
    dish = Dish.create!(user: author, name: "Spam publicada", publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = admin.email

    post sign_in_path, params: { email: admin.email, password: "Password123!" }
    patch revoke_public_share_admin_dish_path(dish)
    follow_redirect! if response.redirect?

    get public_dishes_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Spam publicada")
  end

  # [REQ-MENU-002]
  it "rejects moderation actions for non-admin users" do
    viewer = create(:user, email: "viewer@example.com", password: "Password123!", timezone: "Etc/UTC")
    author = create(:user, password: "Password123!", timezone: "Etc/UTC")
    dish = Dish.create!(user: author, name: "No tocar", publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = "admin@example.com"

    post sign_in_path, params: { email: viewer.email, password: "Password123!" }

    patch revoke_public_share_admin_dish_path(dish)

    expect(response).to have_http_status(:forbidden)
    expect(dish.reload.publicly_shareable).to eq(true)
  end

  # [REQ-EXR-006]
  it "allows an admin to revoke public sharing on an exercise routine" do
    admin = create(:user, email: "admin@example.com", password: "Password123!", timezone: "Etc/UTC")
    author = create(:user, password: "Password123!", timezone: "Etc/UTC")
    routine = ExerciseRoutine.new(user: author, name: "Rutina pública", publicly_shareable: true)
    routine.exercise_routine_lines.build(weekday: 0, position: 0, label: "Press")
    routine.save!

    ENV["MOONLOOP_ADMIN_EMAILS"] = admin.email

    post sign_in_path, params: { email: admin.email, password: "Password123!" }

    patch revoke_public_share_admin_exercise_routine_path(routine)

    expect(response).to have_http_status(:found)
    expect(routine.reload.publicly_shareable).to eq(false)
  end

  # [REQ-EXR-006]
  it "hides a revoked exercise routine from the public catalog" do
    admin = create(:user, email: "admin@example.com", password: "Password123!", timezone: "Etc/UTC")
    author = create(:user, password: "Password123!", timezone: "Etc/UTC")
    routine = ExerciseRoutine.new(user: author, name: "Spam rutina", publicly_shareable: true)
    routine.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
    routine.save!

    ENV["MOONLOOP_ADMIN_EMAILS"] = admin.email

    post sign_in_path, params: { email: admin.email, password: "Password123!" }
    patch revoke_public_share_admin_exercise_routine_path(routine)
    follow_redirect! if response.redirect?

    post sign_in_path, params: { email: author.email, password: "Password123!" }
    get public_exercise_routines_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Spam rutina")
  end

  # [REQ-EXR-006]
  it "rejects exercise routine moderation for non-admin users" do
    viewer = create(:user, email: "viewer-exr@example.com", password: "Password123!", timezone: "Etc/UTC")
    author = create(:user, password: "Password123!", timezone: "Etc/UTC")
    routine = ExerciseRoutine.new(user: author, name: "No moderar", publicly_shareable: true)
    routine.exercise_routine_lines.build(weekday: 0, position: 0, label: "y")
    routine.save!

    ENV["MOONLOOP_ADMIN_EMAILS"] = "admin@example.com"

    post sign_in_path, params: { email: viewer.email, password: "Password123!" }

    patch revoke_public_share_admin_exercise_routine_path(routine)

    expect(response).to have_http_status(:forbidden)
    expect(routine.reload.publicly_shareable).to eq(true)
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

  # [REQ-MENU-006]
  it "removes a menu from the public catalog index after admin revoke" do
    admin = create(:user, email: "admin@example.com", password: "Password123!", timezone: "Etc/UTC")
    viewer = create(:user, email: "viewer-menu@example.com", password: "Password123!", timezone: "Etc/UTC")
    owner = create(:user, password: "Password123!", timezone: "Etc/UTC")
    menu = Menu.create!(user: owner, name: "Listado luego revocado", publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = admin.email

    post sign_in_path, params: { email: viewer.email, password: "Password123!" }
    get public_menus_path
    expect(response.body).to include("Listado luego revocado")

    post sign_in_path, params: { email: admin.email, password: "Password123!" }
    patch "/admin/menus/#{menu.id}/revoke_public_share"
    expect(response).to have_http_status(:found)

    post sign_in_path, params: { email: viewer.email, password: "Password123!" }
    get public_menus_path

    expect(response.body).not_to include("Listado luego revocado")
  end

  # [REQ-PHS-001]
  it "allows an admin to revoke public sharing on a plan" do
    admin = create(:user, email: "admin-plan-mod@example.com", password: "Password123!", timezone: "Etc/UTC")
    owner = create(:user, password: "Password123!", timezone: "Etc/UTC")
    plan = Plan.create!(user: owner, name: "Plan spam", publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = admin.email

    post sign_in_path, params: { email: admin.email, password: "Password123!" }

    patch revoke_public_share_admin_plan_path(plan)

    expect(response).to have_http_status(:found)
    expect(plan.reload.publicly_shareable).to eq(false)
  end

  # [REQ-PHS-001]
  it "removes a plan from the public catalog index after admin revoke" do
    admin = create(:user, email: "admin-plan-mod2@example.com", password: "Password123!", timezone: "Etc/UTC")
    viewer = create(:user, email: "viewer-plan-mod@example.com", password: "Password123!", timezone: "Etc/UTC")
    owner = create(:user, password: "Password123!", timezone: "Etc/UTC")
    plan = Plan.create!(user: owner, name: "Listado plan revocado", publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = admin.email

    post sign_in_path, params: { email: viewer.email, password: "Password123!" }
    get public_plans_path
    expect(response.body).to include("Listado plan revocado")

    post sign_in_path, params: { email: admin.email, password: "Password123!" }
    patch revoke_public_share_admin_plan_path(plan)
    expect(response).to have_http_status(:found)

    post sign_in_path, params: { email: viewer.email, password: "Password123!" }
    get public_plans_path

    expect(response.body).not_to include("Listado plan revocado")
  end

  # [REQ-PHS-001]
  it "rejects plan moderation for non-admin users" do
    viewer = create(:user, email: "viewer-plan-mod3@example.com", password: "Password123!", timezone: "Etc/UTC")
    owner = create(:user, password: "Password123!", timezone: "Etc/UTC")
    plan = Plan.create!(user: owner, name: "No tocar plan", publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = "admin@example.com"

    post sign_in_path, params: { email: viewer.email, password: "Password123!" }

    patch revoke_public_share_admin_plan_path(plan)

    expect(response).to have_http_status(:forbidden)
    expect(plan.reload.publicly_shareable).to eq(true)
  end

  # [REQ-CAT-001] — phases public catalog moderation (REQ-ID finalized in SPEC step S11 of task plan)
  it "allows an admin to revoke public sharing on a phase" do
    admin = create(:user, email: "admin-phase@example.com", password: "Password123!", timezone: "Etc/UTC")
    owner = create(:user, password: "Password123!", timezone: "Etc/UTC")
    phase = Phase.create!(user: owner, name: "Fase spam", weeks_total: 4, publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = admin.email
    post sign_in_path, params: { email: admin.email, password: "Password123!" }

    patch revoke_public_share_admin_phase_path(phase)

    expect(response).to have_http_status(:found)
    expect(phase.reload.publicly_shareable).to eq(false)
  end

  # [REQ-CAT-001] — phases public catalog moderation (REQ-ID finalized in SPEC step S11 of task plan)
  it "removes a phase from the public catalog index after admin revoke" do
    admin = create(:user, email: "admin-phase2@example.com", password: "Password123!", timezone: "Etc/UTC")
    viewer = create(:user, email: "viewer-phase@example.com", password: "Password123!", timezone: "Etc/UTC")
    owner = create(:user, password: "Password123!", timezone: "Etc/UTC")
    phase = Phase.create!(user: owner, name: "Listado fase revocada", weeks_total: 4, publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = admin.email

    post sign_in_path, params: { email: viewer.email, password: "Password123!" }
    get public_phases_path
    expect(response.body).to include("Listado fase revocada")

    post sign_in_path, params: { email: admin.email, password: "Password123!" }
    patch revoke_public_share_admin_phase_path(phase)
    expect(response).to have_http_status(:found)

    post sign_in_path, params: { email: viewer.email, password: "Password123!" }
    get public_phases_path
    expect(response.body).not_to include("Listado fase revocada")
  end

  # [REQ-CAT-001] — phases public catalog moderation (REQ-ID finalized in SPEC step S11 of task plan)
  it "rejects phase moderation for non-admin users" do
    viewer = create(:user, email: "viewer-phase3@example.com", password: "Password123!", timezone: "Etc/UTC")
    owner = create(:user, password: "Password123!", timezone: "Etc/UTC")
    phase = Phase.create!(user: owner, name: "No tocar fase", weeks_total: 4, publicly_shareable: true)

    ENV["MOONLOOP_ADMIN_EMAILS"] = "admin@example.com"
    post sign_in_path, params: { email: viewer.email, password: "Password123!" }

    patch revoke_public_share_admin_phase_path(phase)

    expect(response).to have_http_status(:forbidden)
    expect(phase.reload.publicly_shareable).to eq(true)
  end
end
