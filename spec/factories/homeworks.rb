# frozen_string_literal: true

FactoryBot.define do
  factory :homework do
    classroom
    topic
    due_date { rand((1.day.from_now)..(1.week.from_now)) }
    required { rand(0..100) }
  end
end
