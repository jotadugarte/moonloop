# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public plans adopt", type: :request do
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def routine_with_line(user, name)
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
    r.save!
    r
  end

  # [REQ-PHS-001]
  context "when signed in as adopter" do
    before do
      post sign_in_path, params: { email: adopter.email, password: "Password123!" }
    end

    it "creates an adopted copy with chosen name, segments, and source link" do
      menu = Menu.create!(user: author, name: "Menú origen")
      routine = routine_with_line(author, "Rutina origen")
      origin = Plan.create!(user: author, name: "Plan autor", publicly_shareable: true)
      PlanAssignment.create!(
        plan: origin,
        menu: menu,
        exercise_routine: routine,
        start_week: 2,
        end_week: 5
      )

      expect do
        post adopt_public_plan_path(origin), params: { name: "Mi copia plan" }
      end.to change { Plan.count }.by(1)

      expect(response).to have_http_status(:found)
      copy = Plan.find_by!(user: adopter, name: "Mi copia plan")
      expect(copy.source_plan_id).to eq(origin.id)
      seg = copy.plan_assignments.sole
      expect(seg.start_week).to eq(2)
      expect(seg.menu.user_id).to eq(adopter.id)
      expect(seg.exercise_routine.user_id).to eq(adopter.id)
      expect(response.headers["Location"]).to include(edit_plan_path(copy))
    end

    it "rejects a second adoption of the same origin" do
      menu = Menu.create!(user: author, name: "M")
      routine = routine_with_line(author, "R")
      origin = Plan.create!(user: author, name: "Once", publicly_shareable: true)
      PlanAssignment.create!(plan: origin, menu: menu, exercise_routine: routine, start_week: 1, end_week: 2)

      post adopt_public_plan_path(origin), params: { name: "Primera" }
      expect(response).to have_http_status(:found)

      post adopt_public_plan_path(origin), params: { name: "Segunda" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("public_plans.adopt.errors.already_adopted"))
    end

    it "rejects adoption of the adopter's own public plan" do
      menu = Menu.create!(user: adopter, name: "M own")
      routine = routine_with_line(adopter, "R own")
      own = Plan.create!(user: adopter, name: "Mine", publicly_shareable: true)
      PlanAssignment.create!(plan: own, menu: menu, exercise_routine: routine, start_week: 1, end_week: 2)

      post adopt_public_plan_path(own), params: { name: "Try" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("public_plans.adopt.errors.cannot_adopt_own"))
    end

    it "rejects adoption when the chosen plan name collides for the adopter" do
      Plan.create!(user: adopter, name: "Existing", publicly_shareable: false)
      menu = Menu.create!(user: author, name: "M")
      routine = routine_with_line(author, "R")
      origin = Plan.create!(user: author, name: "Origin", publicly_shareable: true)
      PlanAssignment.create!(plan: origin, menu: menu, exercise_routine: routine, start_week: 1, end_week: 2)

      post adopt_public_plan_path(origin), params: { name: "Existing" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("adoption.invalid_record.name_taken"))
    end
  end

  # [REQ-PHS-001]
  context "when not signed in" do
    it "redirects to sign in" do
      menu = Menu.create!(user: author, name: "M")
      routine = routine_with_line(author, "R")
      origin = Plan.create!(user: author, name: "Publico", publicly_shareable: true)
      PlanAssignment.create!(plan: origin, menu: menu, exercise_routine: routine, start_week: 1, end_week: 2)

      post adopt_public_plan_path(origin), params: { name: "Nope" }

      expect(response).to redirect_to(sign_in_path)
    end
  end
end
