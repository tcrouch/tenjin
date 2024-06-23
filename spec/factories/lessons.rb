# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    category { "youtube" }
    title { FFaker::BaconIpsum.sentence }
    video_id { FFaker::Youtube.video_id }
    topic
  end
end
