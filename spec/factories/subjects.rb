# frozen_string_literal: true

FactoryBot.define do
  factory :subject do
    sequence(:name) { |n| "#{FFaker::Lorem.word} #{n}" }

    factory :computer_science do
      name { "Computer Science" }
    end
  end
end
