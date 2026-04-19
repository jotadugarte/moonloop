# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public exercise routines adopt", type: :request do
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def create_public_routine(user:, name:, label: "Squat")
    r = ExerciseRoutine.new(user: user, name: name, publicly_shareable: true)
    r.exercise_routine_lines.build(weekday: 1, position: 0, label: label)
    r.save!
    r
  end

  # [REQ-EXR-006]
  context "when signed in as adopter" do
    before do
      post sign_in_path, params: { email: adopter.email, password: "Password123!" }
    end

    it "creates an adopted copy with chosen name, lines, and source link" do
      origin = create_public_routine(user: author, name: "Strength A", label: "Deadlift")

      expect do
        post adopt_public_exercise_routine_path(origin), params: { name: "Mi copia" }
      end.to change { ExerciseRoutine.count }.by(1)

      expect(response).to have_http_status(:found)
      copy = ExerciseRoutine.order(:created_at).last
      expect(copy.user_id).to eq(adopter.id)
      expect(copy.name).to eq("Mi copia")
      expect(copy.source_exercise_routine_id).to eq(origin.id)
      expect(copy.exercise_routine_lines.count).to eq(1)
      expect(copy.exercise_routine_lines.first.label).to eq("Deadlift")
      expect(response.headers["Location"]).to include(edit_exercise_routine_path(copy))
    end

    it "rejects a second adoption of the same origin" do
      origin = create_public_routine(user: author, name: "Once")
      post adopt_public_exercise_routine_path(origin), params: { name: "Primera" }
      expect(response).to have_http_status(:found)

      post adopt_public_exercise_routine_path(origin), params: { name: "Segunda" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("public_exercise_routines.adopt.errors.already_adopted"))
    end

    it "rejects adoption when the chosen name collides with an existing routine for the adopter" do
      r = ExerciseRoutine.new(user: adopter, name: "Existing", publicly_shareable: false)
      r.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
      r.save!
      origin = create_public_routine(user: author, name: "Origin", label: "y")

      post adopt_public_exercise_routine_path(origin), params: { name: "Existing" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("adoption.invalid_record.name_taken"))
    end

    it "rejects adoption of the adopter's own public routine" do
      own = create_public_routine(user: adopter, name: "Mine", label: "z")

      post adopt_public_exercise_routine_path(own), params: { name: "Copy try" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("public_exercise_routines.adopt.errors.cannot_adopt_own"))
    end
  end

  # [REQ-EXR-006]
  context "when not signed in" do
    it "redirects to sign in" do
      origin = create_public_routine(user: author, name: "Publico", label: "a")

      post adopt_public_exercise_routine_path(origin), params: { name: "Nope" }

      expect(response).to redirect_to(sign_in_path)
    end
  end
end
