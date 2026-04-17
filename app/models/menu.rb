class Menu < ApplicationRecord
  belongs_to :user
  has_many :menu_entries, dependent: :destroy
  has_many :phase_assignments, dependent: :destroy

  validates :name, presence: true

  normalizes :name, with: -> { _1.strip }
end
