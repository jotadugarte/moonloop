require "rails_helper"

# REQ-HABITS-006: Provisioning runs (enqueued) on first successful login without blocking sign-in.
RSpec.describe "Sessions provisioning", type: :request do
  include ActiveJob::TestHelper

  it "enqueues ProvisionDefaultHabitsJob on successful sign-in" do
    ActiveJob::Base.queue_adapter = :test

    user = create(:user, email: "seedme@example.com", password: "Password123!")

    expect {
      post "/sign_in", params: { email: "seedme@example.com", password: "Password123!" }
    }.to have_enqueued_job(ProvisionDefaultHabitsJob).with(user_id: user.id)
  end
end

