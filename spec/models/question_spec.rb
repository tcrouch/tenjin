# frozen_string_literal: true

require "rails_helper"

RSpec.describe Question, :default_creates do
  let(:mismatched_question) { build(:question, lesson: create(:lesson), topic: topic) }

  it "has a valid factory" do
    expect(build(:question)).to be_valid
  end

  describe "validations" do
    subject { build(:question) }

    it { is_expected.to belong_to(:topic) }
    it { is_expected.to have_many(:answers) }
    it { is_expected.to belong_to(:lesson).optional }
  end

  it "does not allow a mismatched lesson and topic" do
    expect(mismatched_question).not_to be_valid
  end

  context "with a boolean question" do
    let(:boolean_question) { build(:boolean_question) }

    it "accepts boolean answers when true then false, for any case" do
      boolean_question
      Answer.first.update_attribute(:text, "TruE")
      create(:answer, question: question, correct: true, text: "fAlsE")
      expect(question).to be_valid
    end

    it "accepts boolean answers when false then true, for any case" do
      boolean_question
      Answer.first.update_attribute(:text, "FaLsE")
      create(:answer, question: question, correct: true, text: "TrUe")
      expect(question).to be_valid
    end
  end

  it "removes the question from the database when destroyed" do
    question
    expect { question.destroy }.to change(described_class, :count).by(-1)
  end

  describe ".check_boolean" do
    context "when changing a question type to a boolean question" do
      let(:question) { create(:question, question_type: "multiple") }

      it "replaces existing answers with boolean answer choices" do
        answer
        expect { question.update_attribute(:question_type, "boolean") }.to change(Answer, :count).by(1)
      end

      it "automatically creates a false answer" do
        question.update_attribute(:question_type, "boolean")
        expect(Answer.first.text).to eq("False")
      end

      it "automatically creates a true answer" do
        question.update_attribute(:question_type, "boolean")
        expect(Answer.second.text).to eq("True")
      end

      it "sets answers as incorrect" do
        question.update_attribute(:question_type, "boolean")
        expect(Answer.first.correct).to be(false)
      end
    end
  end

  describe ".check_short_answer" do
    let!(:question) { create(:question, question_type: "multiple") }
    let!(:answer) { create(:answer, question: question, correct: false) }

    context "when switching a question to a short answer question" do
      it "changes all existing answers to be correct" do
        question.update_attribute(:question_type, "short_answer")
        expect(Answer.first.correct).to be(true)
      end
    end
  end
end
