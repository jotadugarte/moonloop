require 'rails_helper'

# REQ-HABITS-002: Users manage categories; deletion is blocked when referenced by habits.
RSpec.describe HabitCategory, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:user_habits) }
  end

  describe 'validations' do
    subject { build(:habit_category) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:name_normalized) }
    it { should validate_uniqueness_of(:name_normalized).scoped_to(:user_id) }
  end

  describe 'deletion rules' do
    it 'cannot be deleted while it has user_habits' do
      user = create(:user)
      category = HabitCategory.create!(user: user, name: 'Alimentación', name_normalized: 'alimentación')

      # associated habit
      UserHabit.create!(
        user: user,
        habit_category: category,
        name: 'Agua',
        name_normalized: 'agua',
        active: true
      )

      expect(category.destroy).to be(false)
      expect(category.errors[:base]).not_to be_empty
    end
  end
end

