# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quiz::CreateQuiz, :default_creates do
  context "when creating a lucky dip quiz" do
    let(:quiz) { described_class.call(user: student, topic: "Lucky Dip", subject: quiz_subject) }
    let(:quiz_with_topic) { described_class.call(user: student, topic: topic.id, subject: quiz_subject) }
    let(:topics) { create_list(:topic, 10, subject: quiz_subject) }

    before do
      topics.each do |t|
        create(:question, topic: t)
      end
    end

    it "includes 10 questions" do
      expect(quiz.quiz.questions.count).to eq(10)
    end

    it "excludes inactive questions" do
      Question.first.update_attribute(:active, false)
      expect(quiz.quiz.questions).not_to include(Question.first.id)
    end

    it "draws questions from multiple topics" do
      expect(quiz.quiz.questions.first.topic).not_to eq(quiz.quiz.questions.second.topic)
    end

    it "has no topic assigned for a lucky dip quiz" do
      expect(quiz.quiz.topic).to be_nil
    end

    it "assigns the topic for a non-lucky dip quiz" do
      expect(quiz_with_topic.quiz.topic).to eq(topic)
    end

    it "records the time the quiz was started" do
      quiz
      expect(User.first.time_of_last_quiz).to be_within(1.second).of(Time.current)
    end

    it "returns an error when the cooldown has not elapsed" do
      student.update_attribute(:time_of_last_quiz, Time.current)
      expect(quiz.errors).to match(/You need to wait/)
    end

    it "creates a quiz when there is no previous quiz time" do
      student.update_attribute(:time_of_last_quiz, nil)
      expect(quiz.success?).to be(true)
    end
  end

  context "when creating a lesson based quiz" do
    let(:quiz_with_lesson) do
      described_class.call(user: student, topic: topic.id, subject: quiz_subject, lesson: lesson.id)
    end
    let(:lesson) { create(:lesson, topic: topic) }

    before do
      create_list(:question, 10, topic: topic, lesson: lesson)
      create_list(:question, 20, topic: topic)
    end

    it "includes only questions from the lesson" do
      expect(quiz_with_lesson.quiz.questions.where(lesson: lesson).count).to eq(10)
    end

    it "assigns the lesson to the quiz" do
      expect(quiz_with_lesson.quiz.lesson).to eq(lesson)
    end
  end
end
