class User < ApplicationRecord
  BODY_UNIT_SYSTEMS = %w[metric imperial_us].freeze

  has_secure_password

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end


  has_many :sessions, dependent: :destroy
  has_many :weight_logs, dependent: :destroy
  has_many :habit_categories, dependent: :destroy
  has_many :user_habits, dependent: :destroy
  has_many :menus, dependent: :destroy
  has_many :exercise_routines, dependent: :destroy
  has_many :exercise_routine_assignments, dependent: :destroy
  has_many :recipes, dependent: :destroy
  has_many :phase_assignments, dependent: :destroy
  has_many :phase_programs, dependent: :destroy
  has_many :phase_reminder_events, dependent: :destroy
  has_many :habit_reminder_events, dependent: :destroy
  has_many :web_push_subscriptions, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 12 }

  validates :date_of_birth, :height_cm, :timezone, presence: true
  validates :height_cm, numericality: { greater_than_or_equal_to: 50, less_than_or_equal_to: 300 }, allow_nil: true
  validates :body_unit_system, inclusion: { in: BODY_UNIT_SYSTEMS }

  validate :date_of_birth_must_be_in_valid_range
  validate :timezone_must_be_valid

  attr_readonly :height_cm

  def age
    return nil unless date_of_birth
    now = Date.current
    now.year - date_of_birth.year - ((now.month > date_of_birth.month || (now.month == date_of_birth.month && now.day >= date_of_birth.day)) ? 0 : 1)
  end

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  # Stable, non-PII handle for public catalog attribution (no raw DB id, no email).
  def public_catalog_author_code
    Digest::SHA256.hexdigest("moonloop:public_author:v1:#{id}")[0, 10].upcase
  end

  private

  def date_of_birth_must_be_in_valid_range
    return if date_of_birth.blank?

    if date_of_birth > 10.years.ago.to_date
      errors.add(:date_of_birth, :too_young)
    elsif date_of_birth < 120.years.ago.to_date
      errors.add(:date_of_birth, :too_old)
    end
  end

  def timezone_must_be_valid
    return if timezone.blank?
    valid_zones = ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.name }.to_set
    errors.add(:timezone, :invalid) unless valid_zones.include?(timezone)
  end
end
