# frozen_string_literal: true

FactoryBot.define do
  factory :homework_progress do
    homework
    user
    progress { rand(0..100) }
    completed { [true, false].sample }
  end
end
