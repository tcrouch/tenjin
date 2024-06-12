# frozen_string_literal: true

FactoryBot.define do
  factory :user_statistic do
    questions_answered { rand(0..5000) }
    week_beginning { rand(1..4).weeks.ago.to_date.beginning_of_week }
    user
  end
end
