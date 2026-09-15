# frozen_string_literal: true

require "rails_helper"

RSpec.describe LeaderboardChannel, :default_creates do
  before { stub_connection current_user: student }

  context "when the school belongs to a school group" do
    before { subscribe(subject_id: quiz_subject.id) }

    it "streams the subject's leaderboard for the whole group" do
      expect(subscription.streams)
        .to contain_exactly(described_class.broadcasting_for([quiz_subject, school.school_group]))
    end
  end

  context "when the school has no school group" do
    before do
      school.update!(school_group: nil)
      subscribe(subject_id: quiz_subject.id)
    end

    it "streams the subject's leaderboard for the school" do
      expect(subscription.streams)
        .to contain_exactly(described_class.broadcasting_for([quiz_subject, school]))
    end
  end

  context "when the client names another school" do
    let(:other_school) { create(:school) }

    before do
      subscribe(subject_id: quiz_subject.id, school: other_school.name,
        school_group: other_school.school_group.name)
    end

    it "streams the student's own school group" do
      expect(subscription.streams)
        .to contain_exactly(described_class.broadcasting_for([quiz_subject, school.school_group]))
    end
  end

  context "with an unknown subject" do
    before { subscribe(subject_id: 0) }

    it "rejects the subscription" do
      expect(subscription).to be_rejected
    end
  end
end
