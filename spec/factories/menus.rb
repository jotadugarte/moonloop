FactoryBot.define do
  factory :menu do
    association :user
    sequence(:name) { |n| "Semana #{n}" }
    publicly_shareable { false }
  end
end

