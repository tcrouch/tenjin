# frozen_string_literal: true

FactoryBot.define do
  factory :customisation do
    customisation_type { 'leaderboard_icon' }
    cost { rand(0..10) }
    sequence(:name) { |n| "#{FFaker::Lorem.word} #{n}" }
    sequence(:value) { |n| "#{FFaker::Lorem.word} #{n}" }
    purchasable { true }

    factory :dashboard_customisation do
      customisation_type { 'dashboard_style' }

      after(:build) do |c|
        c.image.attach(io: Rails.root.join('spec/fixtures/files/game-pieces.jpg').open,
                       filename: 'game-pieces.jpeg', content_type: 'image/jpeg')
      end
    end
  end
end
