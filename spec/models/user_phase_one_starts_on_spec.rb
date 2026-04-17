# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User phase one start date", type: :model do
  # [REQ-MENU-003]
  it "stores Phase 1 start date on users.phase_one_starts_on" do
    expect(ActiveRecord::Base.connection.column_exists?(:users, :phase_one_starts_on)).to eq(true)
  end
end
