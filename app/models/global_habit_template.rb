class GlobalHabitTemplate < ApplicationRecord
  has_many :user_habits, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true

  normalizes :code, with: -> { _1.strip.downcase }
end
