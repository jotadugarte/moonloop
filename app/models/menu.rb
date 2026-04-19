# frozen_string_literal: true

class Menu < ApplicationRecord
  belongs_to :user
  belongs_to :source_menu, class_name: "Menu", optional: true, inverse_of: :adopted_copies
  has_many :adopted_copies, class_name: "Menu", foreign_key: :source_menu_id, inverse_of: :source_menu, dependent: :nullify
  has_many :menu_entries, dependent: :destroy
  has_many :phase_assignments, dependent: :destroy

  validates :name, presence: true

  normalizes :name, with: -> { _1.strip }

  before_validation :sync_name_normalized

  validate :name_must_be_unique_for_user

  private

  def sync_name_normalized
    self.name_normalized = name.to_s.strip.downcase
  end

  def name_must_be_unique_for_user
    return if user_id.blank? || name_normalized.blank?

    scope = self.class.where(user_id: user_id, name_normalized: name_normalized)
    scope = scope.where.not(id: id) if persisted?
    errors.add(:name, :taken) if scope.exists?
  end
end
