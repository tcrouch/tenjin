# frozen_string_literal: true

FactoryBot.define do
  factory :homework do
    classroom
    topic
    due_date { rand((Time.current + 1.day)..(Time.current + 1.week)) }
    required { rand(0..100) }
  end
end
