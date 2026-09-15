# frozen_string_literal: true

require "rails_helper"

RSpec.describe Leaderboard::BroadcastLeaderboardPoint, :default_creates do
  before { allow(LeaderboardChannel).to receive(:broadcast_to) }

  context "when the school has a school group" do
    let!(:topic_score) { create(:topic_score, user: student, topic: topic, score: 10) }

    it "broadcasts to a channel scoped to the school group with scores" do
      described_class.call(topic, student)
      expect(LeaderboardChannel).to have_received(:broadcast_to).with(
        [quiz_subject, school.school_group],
        hash_including(id: student.id, topic_score: anything, subject_score: anything)
      )
    end
  end

  context "when the school has no school group" do
    let(:local_student) { create(:student, school: school_without_school_group) }
    let!(:topic_score) { create(:topic_score, user: local_student, topic: topic, score: 5) }

    it "broadcasts to a channel scoped to the school" do
      described_class.call(topic, local_student)
      expect(LeaderboardChannel).to have_received(:broadcast_to)
        .with([quiz_subject, school_without_school_group], anything)
    end
  end
end
