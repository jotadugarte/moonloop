# frozen_string_literal: true

FactoryBot.define do
  factory :phase do
    user
    name { "Fase de prueba" }
    weeks_total { 4 }
  end
end
