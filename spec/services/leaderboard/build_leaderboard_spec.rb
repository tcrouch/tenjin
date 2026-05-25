# frozen_string_literal: true

require "rails_helper"

RSpec.describe Leaderboard::BuildLeaderboard, :default_creates do
  let(:student) { create(:student, forename: "Aaaron", school: school) } # Ensure first alphabetically
  let(:topic_different_subject) { create(:topic) }
  let(:topic_same_subject) { create(:topic, subject: quiz_subject) }
  let(:school) { create(:school, school_group: nil) }
  let(:second_student) { create(:student, school: school) }

  before do
    create(:enrollment, classroom: classroom, user: student)
    create(:topic_score, topic: topic, user: student)
  end

  context "when returning student data" do
    let(:leaderboard) { described_class.call(student, id: quiz_subject.name).first }
    let(:leaderboard_icon) { create(:customisation, customisation_type: "leaderboard_icon") }

    it "includes the school name" do
      expect(leaderboard.school_name).to eq(school.name)
    end

    it "includes the first name and last initial of the student" do
      expect(leaderboard.name).to eq("#{student.forename} #{student.surname.first}")
    end

    it "includes a leaderboard icon if the student has one active" do
      create(:active_customisation, user: student, customisation: leaderboard_icon)
      expect(leaderboard.icon).to eq(leaderboard_icon.value)
    end

    it "includes a leaderboard icon for other students who have one active" do
      create(:active_customisation, user: second_student, customisation: leaderboard_icon)
      create(:topic_score, topic: topic, user: second_student)
      expect(described_class.call(student, id: quiz_subject.name)
        .find { |user| user["id"] == second_student.id }.icon).to eq(leaderboard_icon.value)
    end

    it "returns nil icon for students without an active icon" do
      create(:topic_score, topic: topic, user: second_student)
      expect(described_class.call(student, id: quiz_subject.name)
        .find { |user| user["id"] == second_student.id }.icon).to be_nil
    end
  end

  context "when building a subject leaderboard" do
    let(:leaderboard) { described_class.call(student, id: quiz_subject.name) }

    it "includes students who have scored in the subject" do
      create(:topic_score, topic: topic, school: school, score: 10)
      expect(leaderboard.count).to eq(2)
    end

    it "excludes students from other subjects" do
      create(:topic_score, topic: topic_different_subject, school: school, score: 10)
      expect(leaderboard.count).to eq(1)
    end

    it "sums scores across all topics in the subject" do
      create(:topic_score, user: student, topic: topic_same_subject, school: school)
      expect(leaderboard.first.score).to eq(TopicScore.all.sum(:score))
    end
  end

  context "when building a topic leaderboard" do
    let(:leaderboard) { described_class.call(student, id: quiz_subject.name, topic: topic.id) }

    it "includes students who have scored in the topic" do
      create(:topic_score, topic: topic, school: school, score: 10)
      expect(leaderboard.count).to eq(2)
    end

    it "excludes students who scored in a different topic" do
      create(:topic_score, topic: topic_same_subject, school: school)
      expect(leaderboard.count).to eq(1)
    end

    it "shows only the score for the selected topic" do
      create(:topic_score, topic: topic_same_subject, school: school)
      expect(leaderboard.first.score).to eq(TopicScore.first.score)
    end
  end

  context "when building a leaderboard for a single school" do
    let(:leaderboard) { described_class.call(student, id: quiz_subject.name, topic: topic.id) }
    let(:different_school) { create(:school) }

    it "includes students from the same school" do
      create(:topic_score, topic: topic, school: school)
      expect(leaderboard.count).to eq(2)
    end

    it "excludes students from a different school" do
      create(:topic_score, topic: topic, school: different_school)
      expect(leaderboard.count).to eq(1)
    end
  end

  context "when building a school group leaderboard" do
    let(:school) { create(:school) }
    let(:school_different_school_group) { create(:school) }
    let(:student_no_school_group) { create(:student, school: school_without_school_group) }
    let(:leaderboard) { described_class.call(student, id: quiz_subject.name, school_group: "true") }

    it "excludes students from a different school group" do
      create(:topic_score, topic: topic, school: school_different_school_group)
      expect(leaderboard.count).to eq(1)
    end

    it "includes students from the same school group" do
      create(:topic_score, topic: topic, school: second_school)
      expect(leaderboard.count).to eq(2)
    end

    it "excludes students with no school group" do
      create(:topic_score, topic: topic, user: student_no_school_group)
      expect(leaderboard.count).to eq(1)
    end
  end

  context "when building an all time leaderboard" do
    let(:leaderboard) { described_class.call(student, id: quiz_subject.name, all_time: "true") }

    it "uses all time topic scores instead of weekly scores" do
      create(:all_time_topic_score, user: student, topic: topic)
      expect(leaderboard.first.score).to eq(AllTimeTopicScore.all.sum(:score))
    end
  end
end
