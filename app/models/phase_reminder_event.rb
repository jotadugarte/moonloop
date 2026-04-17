# frozen_string_literal: true

class PhaseReminderEvent < ApplicationRecord
  KIND_PHASE_START = "phase_start"

  belongs_to :user

  validates :kind, presence: true, inclusion: { in: [ KIND_PHASE_START ] }
  validates :local_date, presence: true
end
