class Recipe < ApplicationRecord
  belongs_to :user

  has_many :menu_entries, dependent: :destroy

  has_one_attached :image

  validates :name, presence: true

  normalizes :name, with: -> { _1.strip }
end
