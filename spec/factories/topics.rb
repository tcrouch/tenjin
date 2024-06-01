# frozen_string_literal: true

FactoryBot.define do
  factory :topic do
    name { FFaker::Lorem.word }
    association :subject
    active { true }
  end
end
