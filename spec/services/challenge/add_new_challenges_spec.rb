# frozen_string_literal: true

require "rails_helper"

RSpec.describe Challenge::AddNewChallenges, :default_creates do
  it "creates a challenge for each topic" do
    create_list(:topic, 5)
    described_class.call
    expect(Challenge.count).to eq(5)
  end

  it "sets the duration correctly" do
    create(:topic)
    described_class.call(duration: 3.days)
    expect(Challenge.first.end_date).to be_within(1.second).of(3.days.from_now)
  end

  it "sets the multiplier correctly" do
    srand(1)
    create(:topic)
    described_class.call(multiplier: 4)
    expect(Challenge.first.points).to eq(40)
  end

  it "creates a daily challenge when the daily flag is set" do
    srand(1)
    create(:topic)
    described_class.call(daily: true)
    expect(Challenge.first.daily).to be(true)
  end

  it "defaults to a non-daily challenge" do
    srand(1)
    create(:topic)
    described_class.call
    expect(Challenge.first.daily).to be(false)
  end
end
