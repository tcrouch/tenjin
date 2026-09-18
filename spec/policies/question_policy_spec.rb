# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionPolicy, :default_creates do
  describe "Scope" do
    subject(:resolved) { described_class::Scope.new(author, Question).resolve }

    let(:author) { create(:question_author, subject: quiz_subject) }
    let!(:authored_question) { create(:question, topic: topic) }
    let!(:other_question) { create(:question) }

    it "resolves to the questions in the author's subjects" do
      expect(resolved).to contain_exactly(authored_question)
    end

    context "with a question in an inactive topic of the author's subject" do
      let!(:hidden_question) { create(:question, topic: create(:topic, subject: quiz_subject, active: false)) }

      it "omits it" do
        expect(resolved).not_to include(hidden_question)
      end
    end
  end
end
