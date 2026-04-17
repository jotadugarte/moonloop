# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Weight logs", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  describe "GET /weight_logs/:id/confirm_destroy" do
    context "when signed in" do
      before do
        post sign_in_path, params: { email: user.email, password: "Password123!" }
      end

      # [REQ-WGT-002] [REQ-WGT-003]
      it "renders confirmation for the user's own log" do
        log = create(:weight_log, user: user, weight_kg: 72.0, height_cm: 180)

        get confirm_destroy_weight_log_path(log)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("weight_logs.confirm_destroy.title"))
      end

      # [REQ-WGT-002] [REQ-WGT-003]
      it "returns not found for another user's log" do
        other = create(:user, password: "Password123!", timezone: "Etc/UTC")
        foreign = create(:weight_log, user: other)

        get confirm_destroy_weight_log_path(foreign)

        expect(response).to have_http_status(:not_found)
      end
    end

    # [REQ-WGT-002]
    it "redirects to sign in when not authenticated" do
      log = create(:weight_log, user: user)

      get confirm_destroy_weight_log_path(log)

      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "DELETE /weight_logs/:id" do
    context "when signed in" do
      before do
        post sign_in_path, params: { email: user.email, password: "Password123!" }
      end

      # [REQ-WGT-002] [REQ-WGT-003]
      it "destroys the log and reconciles current stats to the next latest entry" do
        travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
          older = create(:weight_log, user: user, weight_kg: 72.0, height_cm: 180, logged_at: 3.days.ago)
          newer = create(:weight_log, user: user, weight_kg: 75.0, height_cm: 180, logged_at: 1.day.ago)
          WeightLogs::ReconcileUserCurrentStats.call(user: user)
          user.reload
          expect(user.current_weight_kg).to eq(75.0)

          delete weight_log_path(newer)

          expect(response).to redirect_to(profile_path)
          expect(flash[:notice]).to eq(I18n.t("weight_logs.flash.destroyed"))
          expect(WeightLog.exists?(newer.id)).to be false
          user.reload
          expect(user.current_weight_kg).to eq(older.weight_kg)
          expect(user.current_bmi).to eq(older.bmi)
        end
      end

      # [REQ-WGT-002] [REQ-WGT-003]
      it "clears current_weight_kg and current_bmi when deleting the only log" do
        log = create(:weight_log, user: user, weight_kg: 70.0, height_cm: 180)
        WeightLogs::ReconcileUserCurrentStats.call(user: user)
        user.reload
        expect(user.current_weight_kg).to be_present

        delete weight_log_path(log)

        expect(response).to redirect_to(profile_path)
        user.reload
        expect(user.current_weight_kg).to be_nil
        expect(user.current_bmi).to be_nil
      end

      # [REQ-WGT-002] [REQ-WGT-003]
      it "returns not found for another user's log" do
        other = create(:user, password: "Password123!", timezone: "Etc/UTC")
        foreign = create(:weight_log, user: other)

        delete weight_log_path(foreign)

        expect(response).to have_http_status(:not_found)
      end
    end

    # [REQ-WGT-002]
    it "redirects to sign in when not authenticated" do
      log = create(:weight_log, user: user)

      delete weight_log_path(log)

      expect(response).to redirect_to(sign_in_path)
    end
  end
end
