# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quiz::MoveQuizForward, :default_creates do
  let(:questions) { create_list(:question, 5, topic: topic) }
  let(:quiz) do
    q = create(:quiz, num_questions_asked: 4, subject: quiz_subject, topic: topic, user: student, active: true)
    questions.each { |question| create(:asked_question, quiz: q, question: question) }
    q
  end

  before do
    allow(Homework::UpdateHomeworkProgress).to receive(:call)
  end

  it "increments num_questions_asked" do
    expect { described_class.call(quiz: quiz) }.to change { quiz.num_questions_asked }.by(1)
  end

  it "deactivates the quiz when the last question is answered" do
    described_class.call(quiz: quiz)
    expect(quiz.active).to be false
  end

  it "leaves the quiz active when not yet at the last question" do
    early = create(:quiz, num_questions_asked: 1, subject: quiz_subject, topic: topic, user: student, active: true)
    questions.each { |question| create(:asked_question, quiz: early, question: question) }
    described_class.call(quiz: early)
    expect(early.active).to be true
  end

  it "calls UpdateHomeworkProgress when quiz finishes" do
    described_class.call(quiz: quiz)
    expect(Homework::UpdateHomeworkProgress).to have_received(:call).with(quiz: quiz)
  end

  it "does not call UpdateHomeworkProgress when quiz is not finished" do
    early = create(:quiz, num_questions_asked: 1, subject: quiz_subject, topic: topic, user: student, active: true)
    questions.each { |question| create(:asked_question, quiz: early, question: question) }
    described_class.call(quiz: early)
    expect(Homework::UpdateHomeworkProgress).not_to have_received(:call)
  end
end
