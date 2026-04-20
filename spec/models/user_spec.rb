require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    # [REQ-AUTH-001]
    it { should validate_presence_of(:email) }
    # [REQ-PROF-001]
    it { should validate_presence_of(:date_of_birth) }
    # [REQ-PROF-001]
    it { should validate_presence_of(:height_cm) }
    # [REQ-PROF-001]
    it { should validate_presence_of(:timezone) }

    describe 'height_cm validation' do
      # [REQ-PROF-001]
      it 'is valid between 50 and 300' do
        user = build(:user, height_cm: 150)
        expect(user).to be_valid
      end

      # [REQ-PROF-001]
      it 'is invalid if below 50' do
        user = build(:user, height_cm: 49)
        expect(user).not_to be_valid
        expect(user.errors[:height_cm]).to include(
          I18n.t("activerecord.errors.messages.greater_than_or_equal_to", count: 50)
        )
      end

      # [REQ-PROF-001]
      it 'is invalid if above 300' do
        user = build(:user, height_cm: 301)
        expect(user).not_to be_valid
        expect(user.errors[:height_cm]).to include(
          I18n.t("activerecord.errors.messages.less_than_or_equal_to", count: 300)
        )
      end
    end

    describe 'date_of_birth validation' do
      # [REQ-PROF-001]
      it 'is valid if between 10 and 120 years ago' do
        user = build(:user, date_of_birth: 20.years.ago.to_date)
        expect(user).to be_valid
      end

      # [REQ-PROF-001]
      it 'is invalid if less than 10 years ago' do
        user = build(:user, date_of_birth: 9.years.ago.to_date)
        expect(user).not_to be_valid
        expect(user.errors[:date_of_birth]).to include(
          I18n.t("activerecord.errors.models.user.attributes.date_of_birth.too_young")
        )
      end

      # [REQ-PROF-001]
      it 'is invalid if older than 120 years' do
        user = build(:user, date_of_birth: 121.years.ago.to_date)
        expect(user).not_to be_valid
        expect(user.errors[:date_of_birth]).to include(
          I18n.t("activerecord.errors.models.user.attributes.date_of_birth.too_old")
        )
      end
    end

    describe 'body_unit_system validation' do
      # [REQ-PROF-003]
      it 'defaults to metric when creating a user' do
        user = create(:user)
        expect(user.body_unit_system).to eq("metric")
      end

      # [REQ-PROF-003]
      it 'accepts imperial_us' do
        user = build(:user, body_unit_system: "imperial_us")
        expect(user).to be_valid
      end

      # [REQ-PROF-003]
      it 'rejects values outside the closed vocabulary' do
        user = build(:user, body_unit_system: "stone")
        expect(user).not_to be_valid
        expect(user.errors[:body_unit_system]).to include(
          I18n.t("activerecord.errors.models.user.attributes.body_unit_system.inclusion")
        )
      end
    end

    describe 'timezone validation' do
      # [REQ-PROF-001]
      it 'is valid for an IANA timezone' do
        user = build(:user, timezone: 'America/Argentina/Buenos_Aires')
        expect(user).to be_valid
      end

      # [REQ-PROF-001]
      it 'is invalid for a non-IANA string' do
        user = build(:user, timezone: 'Not/A/Timezone')
        expect(user).not_to be_valid
        expect(user.errors[:timezone]).to include(
          I18n.t("activerecord.errors.models.user.attributes.timezone.invalid")
        )
      end
    end
  end

  describe 'Immutability requirements' do
    # [REQ-PROF-001]
    it 'prevents changing height_cm after creation (attr_readonly)' do
      user = create(:user, height_cm: 180)

      expect {
        user.height_cm = 190
      }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end

  describe '#age' do
    # [REQ-PROF-001]
    it 'calculates the correct age based on today as an integer' do
      travel_to Date.new(2026, 4, 16) do
        user_after_bday = build(:user, date_of_birth: Date.new(1996, 4, 15))
        expect(user_after_bday.age).to eq(30)

        user_before_bday = build(:user, date_of_birth: Date.new(1996, 4, 17))
        expect(user_before_bday.age).to eq(29)
      end
    end
  end
end
