class Recipe < ApplicationRecord
  belongs_to :user

  has_one_attached :image

  validates :name, presence: true

  normalizes :name, with: -> { _1.strip }
end
