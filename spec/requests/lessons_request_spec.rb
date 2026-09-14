# frozen_string_literal: true

require "rails_helper"

RSpec.describe "lessons controller", :default_creates do
  describe "GET /lessons" do
    let!(:lesson) { create(:lesson, topic: topic) }
    let!(:enrollment) { create(:enrollment, user: student, classroom: classroom) }

    describe "as a student" do
      let!(:no_content_lesson) do
        create(:lesson, topic: topic, category: "no_content", video_id: nil)
      end

      before { sign_in student }

      it "hides no_content lessons" do
        get lessons_path

        expect(response.body).to include(lesson.title)
        expect(response.body).not_to include(no_content_lesson.title)
      end
    end

    describe "as a lesson author" do
      before do
        teacher.add_role :lesson_author, quiz_subject
        sign_in teacher
      end

      it "shows a create lesson link for authored subjects" do
        get lessons_path

        expect(response.body)
          .to include("Create #{quiz_subject.name} Lesson")
          .and include(new_lesson_path(subject: quiz_subject))
      end

      context "with lessons in multiple subjects" do
        let(:other_subject) { create(:subject, name: "Woodwork") }
        let!(:other_lesson) do
          create(:lesson, title: "Joinery joints", topic: create(:topic, subject: other_subject))
        end

        before { get lessons_path }

        it "lists and offers to edit only lessons in authored subjects" do
          expect(Capybara.string(response.body))
            .to have_link("Edit", count: 1)
            .and have_css(".subject-title", text: quiz_subject.name)
            .and have_no_css(".subject-title", text: other_subject.name)
            .and have_css(".lesson-title", text: lesson.title)
            .and have_no_css(".lesson-title", text: other_lesson.title)
        end

        it "offers to create lessons only in authored subjects" do
          expect(Capybara.string(response.body))
            .to have_css("#createLessons h3", text: quiz_subject.name)
            .and have_no_css("#createLessons h3", text: other_subject.name)
        end
      end
    end
  end

  describe "POST /lessons" do
    let(:title) { "Vimeo video lesson" }
    let(:params) do
      {lesson: {title: title, video_link: "https://vimeo.com/371104836", topic_id: topic.id}}
    end

    before do
      teacher.add_role :lesson_author, quiz_subject
      sign_in teacher
    end

    it "creates the lesson and redirects to the index" do
      expect { post lessons_path, params: params }.to change(Lesson, :count).by(1)
      expect(Lesson.find_by!(title: title))
        .to have_attributes(topic: topic, category: "vimeo", video_id: "371104836")
      expect(response).to redirect_to(lessons_path)
    end

    context "when the details are invalid" do
      let(:title) { "ab" }

      it "re-renders the new form with errors" do
        expect { post lessons_path, params: params }.not_to change(Lesson, :count)
        expect(Capybara.string(response.body))
          .to have_css("h1", text: "Create Lesson")
          .and have_css(".invalid-feedback", text: "too short")
      end
    end
  end

  describe "PATCH /lessons/:id" do
    let(:lesson) { create(:lesson, topic: topic) }

    before do
      teacher.add_role :lesson_author, quiz_subject
      sign_in teacher
    end

    it "saves the new details and redirects to the index" do
      patch lesson_path(lesson), params: {lesson: {title: "Fantastic new title"}}
      expect(lesson.reload.title).to eq("Fantastic new title")
      expect(response).to redirect_to(lessons_path)
    end

    context "when the details are invalid" do
      it "re-renders the edit form with errors" do
        expect { patch lesson_path(lesson), params: {lesson: {title: "ab"}} }
          .not_to change { lesson.reload.title }
        expect(Capybara.string(response.body))
          .to have_css("h1", text: "Update Lesson")
          .and have_css(".invalid-feedback", text: "too short")
      end
    end
  end

  describe "DELETE /lessons/:id" do
    let!(:lesson) { create(:lesson, topic: topic) }

    before do
      teacher.add_role :lesson_author, quiz_subject
      sign_in teacher
    end

    it "destroys the lesson and redirects to the index" do
      expect { delete lesson_path(lesson) }.to change(Lesson, :count).by(-1)
      expect(response).to redirect_to(lessons_path)
    end
  end
end
