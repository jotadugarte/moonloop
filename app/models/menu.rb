class Menu < ApplicationRecord
  belongs_to :user
  has_many :menu_entries, dependent: :destroy

  validates :name, presence: true

  normalizes :name, with: -> { _1.strip }
end
