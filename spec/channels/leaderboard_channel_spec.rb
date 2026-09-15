# frozen_string_literal: true

require "rails_helper"

RSpec.describe LeaderboardChannel, :default_creates do
  let(:viewer) { student }

  before { stub_connection current_user: viewer }

  context "when the school belongs to a school group" do
    before do
      subscribe(subject_id: quiz_subject.id, school: "Another School", school_group: "Another Group")
    end

    it "streams the group's leaderboard, ignoring the school the client names" do
      expect(subscription.streams)
        .to contain_exactly(described_class.broadcasting_for([quiz_subject, school.school_group]))
    end
  end

  context "when the school has no school group" do
    let(:viewer) { create(:student, school: school_without_school_group) }

    before { subscribe(subject_id: quiz_subject.id) }

    it "streams the school's leaderboard" do
      expect(subscription.streams)
        .to contain_exactly(described_class.broadcasting_for([quiz_subject, school_without_school_group]))
    end
  end

  context "with an unknown subject" do
    before { subscribe(subject_id: 0) }

    it "rejects the subscription" do
      expect(subscription).to be_rejected
    end
  end
end
