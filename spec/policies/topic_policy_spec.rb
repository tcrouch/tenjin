# frozen_string_literal: true

require "rails_helper"

RSpec.describe TopicPolicy, :default_creates do
  describe "Scope" do
    subject(:resolved) { described_class::Scope.new(author, Topic).resolve }

    let(:author) { create(:question_author, subject: quiz_subject) }
    let!(:topic) { super() }
    let!(:other_topic) { create(:topic) }

    it "resolves to the topics in the author's subjects" do
      expect(resolved).to contain_exactly(topic)
    end

    context "with an inactive topic in the author's subject" do
      let!(:inactive_topic) { create(:topic, subject: quiz_subject, active: false) }

      it "omits it" do
        expect(resolved).not_to include(inactive_topic)
      end
    end

    context "with an inactive subject the author holds the role on" do
      let(:inactive_subject) { create(:subject, active: false) }
      let!(:hidden_topic) { create(:topic, subject: inactive_subject) }

      before { author.add_role(:question_author, inactive_subject) }

      it "omits its topics" do
        expect(resolved).not_to include(hidden_topic)
      end
    end
  end
end
