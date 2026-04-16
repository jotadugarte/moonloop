require "rails_helper"

RSpec.describe "Sessions provisioning", type: :request do
  include ActiveJob::TestHelper

  # [REQ-AUTH-002, REQ-HAB-002]
  it "enqueues ProvisionDefaultHabitsJob on successful sign-in" do
    ActiveJob::Base.queue_adapter = :test

    user = create(:user, email: "seedme@example.com", password: "Password123!")

    expect {
      post "/sign_in", params: { email: "seedme@example.com", password: "Password123!" }
    }.to have_enqueued_job(ProvisionDefaultHabitsJob).with(user_id: user.id)
  end
end
