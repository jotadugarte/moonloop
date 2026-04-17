# frozen_string_literal: true

module Habits
  # Active user habits due on +local_date+ (civil date in the user's calendar; caller supplies the date).
  #
  # Due-day rules live in {DueOnDate}; we load active habits for the user and filter in Ruby (O(n) in
  # active habit count). This matches current product scale; revisit with SQL or batching if needed.
  class DueHabitsForDay
    def self.call(user:, local_date:)
      new(user: user, local_date: local_date).call
    end

    def initialize(user:, local_date:)
      @user = user
      @local_date = local_date
    end

    def call
      @user.user_habits
           .where(active: true)
           .includes(:habit_category, :user)
           .order(created_at: :asc)
           .select { |uh| DueOnDate.due_on?(uh, @local_date) }
    end
  end
end
