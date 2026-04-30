# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public phases adopt", type: :request do
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  # [REQ-CAT-001] — phases public catalog adoption (REQ-ID finalized in SPEC step S11 of task plan)
  context "when signed in as adopter" do
    before do
      post sign_in_path, params: { email: adopter.email, password: "Password123!" }
    end

    it "creates an adopted copy with chosen name and source link" do
      origin = Phase.create!(user: author, name: "Fase autor", weeks_total: 4, publicly_shareable: true)

      expect do
        post adopt_public_phase_path(origin), params: { name: "Mi copia fase" }
      end.to change { Phase.count }.by(1)

      expect(response).to have_http_status(:found)
      copy = Phase.find_by!(user: adopter, name: "Mi copia fase")
      expect(copy.source_phase_id).to eq(origin.id)
      expect(copy.adoption_catalog_origin_id).to eq(origin.id)
      expect(copy.publicly_shareable).to eq(false)
      expect(copy.weeks_total).to eq(4)

      origin.reload
      expect(origin.public_catalog_adoptions_count).to eq(1)
      expect(origin.public_catalog_distinct_adopters_count).to eq(1)
    end

    it "rejects a second adoption of the same origin" do
      origin = Phase.create!(user: author, name: "Once", weeks_total: 4, publicly_shareable: true)

      post adopt_public_phase_path(origin), params: { name: "Primera" }
      expect(response).to have_http_status(:found)

      post adopt_public_phase_path(origin), params: { name: "Segunda" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("public_phases.adopt.errors.already_adopted"))
    end

    it "rejects adoption of the adopter's own public phase" do
      own = Phase.create!(user: adopter, name: "Mía", weeks_total: 4, publicly_shareable: true)

      post adopt_public_phase_path(own), params: { name: "Try" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("public_phases.adopt.errors.cannot_adopt_own"))
    end

    it "rejects adoption when the chosen phase name collides for the adopter" do
      Phase.create!(user: adopter, name: "Existing", weeks_total: 4, publicly_shareable: false)
      origin = Phase.create!(user: author, name: "Origin", weeks_total: 4, publicly_shareable: true)

      post adopt_public_phase_path(origin), params: { name: "Existing" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("adoption.invalid_record.name_taken"))
    end
  end

  # [REQ-CAT-001] — phases public catalog adoption (REQ-ID finalized in SPEC step S11 of task plan)
  context "when not signed in" do
    it "redirects to sign in" do
      origin = Phase.create!(user: author, name: "Publica", weeks_total: 4, publicly_shareable: true)

      post adopt_public_phase_path(origin), params: { name: "Nope" }

      expect(response).to redirect_to(sign_in_path)
    end
  end
end

