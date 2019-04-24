require 'rails_helper'
require 'support/session_helpers'

RSpec.describe Question, type: :model, default_creates: true do
  it 'deletes answers when being deleted' do
    answer
    expect { question.destroy }.to change(Question, :count).by(-1)
  end

  describe '.clean_empty_questions' do
    context 'when saving a question with no text' do
      it 'deletes questions that have no text' do
        question = create(:question, question_text: nil)
        expect { Question.clean_empty_questions(question.topic) }.to change(Question, :count).by(-1)
      end

      it 'does not delete questions that have text' do
        create(:question)
        expect(Question.count).to eq(1)
      end
    end
  end

  describe '.check_boolean' do
    context 'when changing a question type to a boolean question' do
      let(:question) { create(:question, question_type: 'multiple') }

      it 'deletes existing answers' do
        answer
        expect { question.update_attribute(:question_type, 'boolean') }.to change(Answer, :count).by(1)
      end

      it 'automatically creates a false answer' do
        question.update_attribute(:question_type, 'boolean')
        expect(Answer.first.text).to eq('False')
      end

      it 'automatically creates a true answer' do
        question.update_attribute(:question_type, 'boolean')
        expect(Answer.second.text).to eq('True')
      end

      it 'sets answers as incorrect' do
        question.update_attribute(:question_type, 'boolean')
        expect(Answer.first.correct).to eq(false)
      end
    end
  end

  describe '.check_short_answer' do
    let(:question) { create(:question, question_type: 'multiple') }
    let(:answer) { create(:answer, question: question, correct: false)}

    context 'when switching a question to a short answer question' do
      it 'changes all existing answers to be correct' do
        answer
        question.update_attribute(:question_type, 'short_answer')
        expect(Answer.first.correct).to eq(true)
      end
    end
  end
end
