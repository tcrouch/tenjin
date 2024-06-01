# frozen_string_literal: true

FactoryBot.define do
  factory :challenge do
    challenge_type { Challenge.challenge_types.values.sample }
    number_required { rand(4..10) }
    start_date { Time.current }
    end_date { Time.current + 7.days }
    points { 10 }
    topic
    daily { false }
  end
end
