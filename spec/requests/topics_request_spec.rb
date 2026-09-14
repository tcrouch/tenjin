# frozen_string_literal: true

require "rails_helper"

RSpec.describe "topics controller", :default_creates do
  let(:author) { create(:question_author, subject: quiz_subject) }

  before { sign_in author }

  describe "GET /topics/new" do
    it "creates a topic for the subject and redirects to its questions" do
      expect { get new_topic_path(subject: {subject_id: quiz_subject.id}) }
        .to change(Topic, :count).by(1)
      expect(response).to redirect_to(topic_questions_path(topic_id: Topic.last))
    end
  end

  describe "PATCH /topics/:id" do
    it "renames the topic" do
      expect { patch topic_path(topic), params: {topic: {name: "Fractions"}} }
        .to change { topic.reload.name }.to("Fractions")
      expect(response).to have_http_status(:no_content)
    end

    context "with a lesson for the topic" do
      let(:lesson) { create(:lesson, topic: topic) }

      it "sets the default lesson" do
        expect { patch topic_path(topic), params: {topic: {default_lesson_id: lesson.id}} }
          .to change { topic.reload.default_lesson }.from(nil).to(lesson)
      end
    end
  end

  describe "DELETE /topics/:id" do
    it "destroys the topic and redirects to the questions index" do
      expect { delete topic_path(topic) }
        .to change { Topic.exists?(topic.id) }.from(true).to(false)
      expect(response).to redirect_to(questions_path)
    end
  end
end
