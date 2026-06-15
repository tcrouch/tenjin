# frozen_string_literal: true

require "rails_helper"

RSpec.describe Leaderboard::BroadcastLeaderboardPoint, :default_creates do
  let!(:topic_score) { create(:topic_score, user: student, topic: topic, score: 10) }

  before do
    allow(LeaderboardChannel).to receive(:broadcast_to)
  end

  it "broadcasts to LeaderboardChannel" do
    described_class.call(topic, student)
    expect(LeaderboardChannel).to have_received(:broadcast_to)
  end

  it "uses the school group name in the channel string when present" do
    described_class.call(topic, student)
    expected_channel = "#{topic.subject.name}:#{student.school.school_group.name}"
    expect(LeaderboardChannel).to have_received(:broadcast_to).with(expected_channel, anything)
  end

  it "uses the school name in the channel string when no school group" do
    school_without_group = create(:school, school_group: nil)
    local_student = create(:student, school: school_without_group)
    create(:topic_score, user: local_student, topic: topic, score: 5)
    described_class.call(topic, local_student)
    expected_channel = "#{topic.subject.name}:#{school_without_group.name}"
    expect(LeaderboardChannel).to have_received(:broadcast_to).with(expected_channel, anything)
  end

  it "includes the user id and scores in the payload" do
    described_class.call(topic, student)
    expect(LeaderboardChannel).to have_received(:broadcast_to).with(
      anything,
      hash_including(id: student.id, topic_score: anything, subject_score: anything)
    )
  end
end
