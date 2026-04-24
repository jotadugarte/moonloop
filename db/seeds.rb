# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

DEMO_USERS = [
  {
    email: "demo+mx-metric@moonloop.local",
    timezone: "America/Mexico_City",
    body_unit_system: "metric"
  },
  {
    email: "demo+es-imperial@moonloop.local",
    timezone: "Europe/Madrid",
    body_unit_system: "imperial_us"
  },
  {
    email: "demo+us-metric@moonloop.local",
    timezone: "America/Los_Angeles",
    body_unit_system: "metric"
  }
].freeze unless defined?(DEMO_USERS)

def seed_demo_users!
  raise "DEMO_USERS must be present" if DEMO_USERS.empty?

  DEMO_USERS.each do |attrs|
    raise "demo email required" if attrs[:email].blank?
    raise "demo timezone required" if attrs[:timezone].blank?

    user = User.find_or_initialize_by(email: attrs[:email])

    user.assign_attributes(
      timezone: attrs[:timezone],
      body_unit_system: attrs[:body_unit_system]
    )
    if user.new_record?
      user.assign_attributes(
        date_of_birth: Date.new(1990, 1, 1),
        height_cm: 175
      )
    end
    user.password = "moonloop-demo-password"
    user.password_confirmation = "moonloop-demo-password"

    user.save!

    ProvisionDefaultHabitsJob.perform_now(user_id: user.id)
  end

  demo_count = User.where(email: DEMO_USERS.map { |u| u[:email] }).count
  raise "expected 3 demo users, got #{demo_count}" unless demo_count == 3
end

seed_demo_users!
