# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quiz, :default_creates do
  let(:quiz) { create(:quiz, user: student, topic: topic) }
  let(:usage_statistic) { UsageStatistic.where(user: student).last }
  let(:old_statistic) { create(:usage_statistic, user: student, date: 1.day.ago) }

  it "has a valid factory" do
    expect(build(:quiz)).to be_valid
  end

  context "when creating a quiz" do
    it "creates a usage statistic for today" do
      quiz
      expect(usage_statistic.quizzes_started).to eq(1)
    end

    it "does not update statistics for other days" do
      old_statistic
      quiz
      expect(usage_statistic.quizzes_started).to eq(1)
    end

    it "creates a new statistic record rather than updating an existing one" do
      old_statistic
      quiz
      expect(usage_statistic.id).not_to eq(old_statistic.id)
    end
  end
end
