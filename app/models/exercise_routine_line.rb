# frozen_string_literal: true

class ExerciseRoutineLine < ApplicationRecord
  belongs_to :exercise_routine, inverse_of: :exercise_routine_lines

  validates :weekday, inclusion: { in: 0..6 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :position, uniqueness: { scope: [ :exercise_routine_id, :weekday ] }
  validates :label, presence: true, length: { maximum: 500 }

  normalizes :label, with: -> { _1.strip }
end
