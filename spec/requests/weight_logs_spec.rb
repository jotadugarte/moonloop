# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Weight logs", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  describe "GET /weight_logs" do
    context "when signed in" do
      before do
        post sign_in_path, params: { email: user.email, password: "Password123!" }
      end

      # [REQ-WGT-003]
      it "renders empty state when there are no logs" do
        get weight_logs_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("weight_logs.index.empty"))
      end

      # [REQ-WGT-003]
      it "lists logs with newest logged_at first" do
        travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
          create(:weight_log, user: user, weight_kg: 22.22, height_cm: 180, logged_at: 5.days.ago)
          create(:weight_log, user: user, weight_kg: 88.88, height_cm: 180, logged_at: 1.day.ago)

          get weight_logs_path

          body = response.body
          expect(body.index("88.88")).to be < body.index("22.22")
        end
      end

      # [REQ-WGT-003, REQ-WGT-004]
      it "formats weights and snapshot height using the viewer's current unit preference" do
        imperial = create(:user, password: "Password123!", timezone: "Etc/UTC", body_unit_system: "imperial_us", height_cm: 175)
        post sign_in_path, params: { email: imperial.email, password: "Password123!" }
        create(:weight_log, user: imperial, weight_kg: 70.0, height_cm: 180, logged_at: Time.utc(2026, 4, 10, 12, 0, 0))

        get weight_logs_path

        expect(response.body).to include("154.3")
        expect(response.body).to include(I18n.t("body_metrics.height_ft_in", feet: 5, inches: 11))
      end

      # [REQ-WGT-003]
      it "shows 30 entries per page and a link to the next page when there are more" do
        travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
          31.times do |i|
            create(:weight_log, user: user, weight_kg: 70.0, height_cm: 180, logged_at: i.days.ago)
          end

          get weight_logs_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("page=2")
          expect(response.body).to include(I18n.t("weight_logs.index.pagination.next"))
        end
      end

      # [REQ-WGT-003]
      it "includes a delete link to the confirmation screen for each row" do
        log = create(:weight_log, user: user, weight_kg: 72.0, height_cm: 180)

        get weight_logs_path

        expect(response.body).to include(confirm_destroy_weight_log_path(log))
      end

      # [REQ-WGT-003]
      it "shows a previous link on page 2" do
        travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
          31.times do |i|
            create(:weight_log, user: user, weight_kg: 70.0, height_cm: 180, logged_at: i.days.ago)
          end

          get weight_logs_path(page: 2)

          expect(response.body).to include(I18n.t("weight_logs.index.pagination.previous"))
        end
      end
    end

    # [REQ-WGT-003]
    it "redirects to sign in when not authenticated" do
      get weight_logs_path

      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "GET /weight_logs/new" do
    context "when signed in" do
      before do
        post sign_in_path, params: { email: user.email, password: "Password123!" }
      end

      # [REQ-WGT-002]
      it "renders the weight entry form" do
        get new_weight_log_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("weight_logs.new.title"))
        expect(response.body).to include("weight_log_weight_kg")
        expect(response.body).to include("weight_log_logged_at")
      end

      # [REQ-WGT-002, REQ-WGT-004]
      it "renders pounds field when the user prefers imperial US" do
        imperial = create(:user, password: "Password123!", timezone: "Etc/UTC", body_unit_system: "imperial_us")
        post sign_in_path, params: { email: imperial.email, password: "Password123!" }

        get new_weight_log_path

        expect(response.body).to include("weight_log_weight_lb")
        expect(response.body).not_to include("weight_log_weight_kg")
      end
    end

    # [REQ-WGT-002]
    it "redirects to sign in when not authenticated" do
      get new_weight_log_path

      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "POST /weight_logs" do
    context "when signed in" do
      before do
        post sign_in_path, params: { email: user.email, password: "Password123!" }
      end

      # [REQ-WGT-002]
      it "creates a weight log and redirects with notice" do
        travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
          expect {
            post weight_logs_path,
              params: {
                weight_log: {
                  weight_kg: "78.2",
                  logged_at: "2026-04-16T10:30"
                }
              }
          }.to change(WeightLog, :count).by(1)

          expect(response).to redirect_to(edit_profile_path)
          expect(flash[:notice]).to eq(I18n.t("weight_logs.flash.created"))

          log = WeightLog.order(:id).last
          expect(log.weight_kg).to eq(78.2)
          user.reload
          expect(user.current_weight_kg).to eq(78.2)
        end
      end

      # [REQ-PROF-002, REQ-WGT-002]
      it "creates a weight log for a user with no initial current weight and reconciles current stats" do
        nil_stats_user = create(
          :user,
          password: "Password123!",
          timezone: "Etc/UTC",
          height_cm: 180,
          current_weight_kg: nil,
          current_bmi: nil
        )
        post sign_in_path, params: { email: nil_stats_user.email, password: "Password123!" }

        travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
          post weight_logs_path,
            params: {
              weight_log: {
                weight_kg: "80.0",
                logged_at: "2026-04-16T10:30"
              }
            }

          expect(response).to redirect_to(edit_profile_path)
          nil_stats_user.reload
          expect(nil_stats_user.current_weight_kg).to eq(80.0)
          expect(nil_stats_user.current_bmi).to be_present
        end
      end

      # [REQ-WGT-002, REQ-WGT-004]
      it "accepts pounds and persists canonical kg for imperial users" do
        imperial = create(:user, password: "Password123!", timezone: "Etc/UTC", height_cm: 180, body_unit_system: "imperial_us")
        post sign_in_path, params: { email: imperial.email, password: "Password123!" }

        travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
          expect {
            post weight_logs_path,
              params: {
                weight_log: {
                  weight_lb: "176.37",
                  logged_at: "2026-04-16T10:30"
                }
              }
          }.to change(WeightLog, :count).by(1)

          log = WeightLog.order(:id).last
          expect(log.weight_kg).to be_within(0.02).of(80.0)
          imperial.reload
          expect(imperial.current_weight_kg).to be_within(0.02).of(80.0)
        end
      end

      # [REQ-WGT-002, REQ-WGT-004]
      it "re-renders when weight_lb is blank for imperial users" do
        imperial = create(:user, password: "Password123!", timezone: "Etc/UTC", body_unit_system: "imperial_us")
        post sign_in_path, params: { email: imperial.email, password: "Password123!" }

        travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
          expect {
            post weight_logs_path,
              params: {
                weight_log: {
                  weight_lb: "",
                  logged_at: "2026-04-16T10:30"
                }
              }
          }.not_to change(WeightLog, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include(I18n.t("weight_logs.errors.weight_blank"))
        end
      end

      # [REQ-WGT-002]
      it "re-renders with errors when weight_kg is out of domain" do
        travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
          expect {
            post weight_logs_path,
              params: {
                weight_log: {
                  weight_kg: "10",
                  logged_at: "2026-04-16T10:30"
                }
              }
          }.not_to change(WeightLog, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("role=\"alert\"")
        end
      end

      # [REQ-WGT-002]
      it "re-renders when logged_at is in the future" do
        travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
          post weight_logs_path,
            params: {
              weight_log: {
                weight_kg: "70",
                logged_at: "2026-04-17T14:00"
              }
            }

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("role=\"alert\"")
          expect(response.body).to include(
            I18n.t("activerecord.errors.models.weight_log.attributes.logged_at.future_timestamp")
          )
        end
      end
    end

    # [REQ-WGT-002]
    it "redirects to sign in when not authenticated" do
      post weight_logs_path,
        params: {
          weight_log: {
            weight_kg: "70",
            logged_at: "2026-04-10T12:00"
          }
        }

      expect(response).to redirect_to(sign_in_path)
    end
  end

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

          expect(response).to redirect_to(weight_logs_path)
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

        expect(response).to redirect_to(weight_logs_path)
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
