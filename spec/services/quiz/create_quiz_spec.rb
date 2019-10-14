require 'rails_helper'

RSpec.describe Quiz::CreateQuiz, '#call' do
  include_context 'default_creates'

  context 'when creating a lucky dip' do
    let(:quiz) { Quiz::CreateQuiz.new(user: student, topic: 'Lucky Dip', subject: subject).call }
    let(:quiz_with_topic) { Quiz::CreateQuiz.new(user: student, topic: topic.id, subject: subject).call }
    let(:topics) { create_list(:topic, 10, subject: subject) }

    before do
      topics.each do |t|
        create(:question, topic: t)
      end
    end

    it 'has 10 questions' do
      expect(quiz.quiz.questions.count).to eq(10)
    end

    it 'creates a lucky dip' do
      expect(quiz.quiz.questions.first.topic).not_to eq(quiz.quiz.questions.second.topic)
    end

    it 'does not have a topic for a lucky dip quiz' do
      expect(quiz.quiz.topic).to eq(nil)
    end

    it 'sets the topic id for a non-lucky dip quiz' do
      expect(quiz_with_topic.quiz.topic).to eq(topic)
    end

    it 'logs the current date and time' do
      quiz
      expect(User.first.time_of_last_quiz).to be_within(1.second).of(Time.now)
    end

    it 'returns an error if cooldown has not elapsed' do
      student.update_attribute(:time_of_last_quiz, Time.now)
      expect(quiz.errors).to match(/You need to wait/)
    end

    it 'creates a quiz if there is currently no time of last quiz' do
      student.update_attribute(:time_of_last_quiz, nil)
      expect(quiz.success?).to eq(true)
    end
  end
end