# frozen_string_literal: true

require "rails_helper"

RSpec.describe "questions controller", :default_creates do
  let(:author) { create(:question_author, subject: quiz_subject) }

  describe "GET /questions" do
    context "as a student" do
      before { sign_in student }

      it "redirects to the dashboard" do
        get questions_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "as a question author" do
      before { sign_in author }

      it "returns a success response" do
        get questions_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /questions/topic" do
    let(:question) { create(:question, topic: topic) }
    let!(:flags) { create_list(:flagged_question, 5, question: question, user: student) }

    before do
      sign_in author
      get topic_questions_path(topic_id: topic.id)
    end

    it "shows each question's flag count" do
      expect(Capybara.string(response.body))
        .to have_css("#question-#{question.id} td.flags", exact_text: "5")
    end
  end

  describe "GET /questions/flagged_questions" do
    let!(:flagged_question) { create(:question, topic: topic, flagged_questions_count: 5) }

    before do
      sign_in author
      get flagged_questions_questions_path(subject_id: quiz_subject.id)
    end

    it "lists the subject's flagged questions" do
      expect(Capybara.string(response.body)).to have_css("#question-#{flagged_question.id}")
    end

    it "does not list unflagged questions"
  end

  describe "GET /questions/:id" do
    let(:question) { create(:question, topic: topic) }

    before { sign_in author }

    it "labels each select" do
      get question_path(question)
      expect(Capybara.string(response.body))
        .to have_select("Question Type").and have_select("Lesson:").and have_select("Topic:")
    end

    context "with a short answer question" do
      let(:question) { create(:short_answer_question, topic: topic) }

      before { get question_path(question) }

      it "hides the correct answer toggle" do
        expect(Capybara.string(response.body)).to have_no_css("#table-answers th", text: "Correct?")
      end
    end

    context "when previewing the question as boolean" do
      before { get question_path(question, question: {question_type: "boolean"}) }

      it "hides the remove answer links" do
        expect(Capybara.string(response.body)).to have_no_link("Remove")
      end
    end

    context "with a multiple choice question" do
      it "shows the correct answer toggle"
      it "shows a remove link for each answer"
    end
  end

  describe "PATCH /questions/:id" do
    let(:question) { create(:question, topic: topic) }
    let(:correct_answer) { question.answers.find_by!(correct: true) }

    before { sign_in author }

    context "with a lesson for the topic" do
      let(:lesson) { create(:lesson, topic: topic) }

      it "assigns the lesson" do
        expect { patch question_path(question), params: {question: {lesson_id: lesson.id}} }
          .to change { question.reload.lesson }.from(nil).to(lesson)
        expect(response).to redirect_to(question)
        expect(flash[:notice]).to eq("Question successfully updated")
      end
    end

    it "adds an answer" do
      patch question_path(question), params: {question: {answers_attributes: {"0" => {text: "Photosynthesis"}}}}
      expect(question.answers.reload).to contain_exactly(
        have_attributes(correct: true),
        have_attributes(text: "Photosynthesis")
      )
    end

    it "updates an answer's text" do
      expect do
        patch question_path(question),
          params: {question: {answers_attributes: {"0" => {id: correct_answer.id, text: "Photosynthesis"}}}}
      end.to change { correct_answer.reload.text }.to("Photosynthesis")
    end

    context "with an incorrect answer" do
      let(:incorrect_answer) { create(:answer, question: question, correct: false) }

      it "removes an answer flagged for destruction" do
        expect do
          patch question_path(question),
            params: {question: {answers_attributes: {"0" => {id: incorrect_answer.id, _destroy: "true"}}}}
        end.to change { Answer.exists?(incorrect_answer.id) }.from(true).to(false)
      end
    end

    context "when the only correct answer is removed" do
      it "keeps the answer and re-renders the editor with an error" do
        expect do
          patch question_path(question),
            params: {question: {answers_attributes: {"0" => {id: correct_answer.id, _destroy: "true"}}}}
        end.not_to change { Answer.exists?(correct_answer.id) }
        expect(response.body).to include("Question must have at least one correct answer")
      end
    end

    context "when no answer is marked correct" do
      before do
        patch question_path(question),
          params: {question: {answers_attributes: {"0" => {id: correct_answer.id, correct: "0"}}}}
      end

      it "re-renders the editor with an error" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Question must have at least one correct answer")
      end
    end

    context "with a short answer question" do
      let(:question) { create(:short_answer_question, topic: topic) }

      before do
        patch question_path(question), params: {question: {answers_attributes: {"0" => {text: "Photosynthesis"}}}}
      end

      it "marks every answer correct" do
        expect(question.answers.reload).to all(be_correct)
        expect(flash[:notice]).to eq("Question successfully updated")
      end
    end
  end

  describe "DELETE /questions/:id" do
    let(:question) { create(:question, topic: topic) }

    before { sign_in author }

    it "deactivates the question and redirects to its topic" do
      expect { delete question_path(question) }
        .to change { question.reload.active }.from(true).to(false)
      expect(response).to redirect_to(topic_questions_path(topic_id: topic))
    end
  end

  describe "PATCH /questions/:id/reset_flags" do
    let(:question) { create(:question, topic: topic) }
    let!(:flag) { create(:flagged_question, question: question, user: student) }

    before { sign_in author }

    it "clears the question's flags" do
      expect { patch reset_flags_question_path(question) }
        .to change { question.reload.flagged_questions_count }.from(1).to(0)
      expect(response).to redirect_to(question)
    end

    context "when not authorized for the question's subject" do
      let(:author) { create(:question_author, subject: create(:subject)) }

      it "keeps the flags and redirects with an alert" do
        expect { patch reset_flags_question_path(question) }.not_to change(FlaggedQuestion, :count)
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("You are not authorized to perform this action.")
      end
    end
  end

  describe "GET /questions/download_topic" do
    let!(:question) { create(:question, topic: topic) }

    before { sign_in author }

    it "responds with the questions as a JSON attachment named after the topic" do
      get download_topic_questions_path(topic_id: topic.id)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(response.headers["Content-Disposition"])
        .to include("attachment").and include("filename=#{topic.name}.json")
      expect(JSON.parse(response.body).first).to include("question_text", "answers")
    end
  end

  describe "POST /questions/import" do
    before { sign_in author }

    context "without an attached file" do
      it "re-renders the import form with an alert" do
        post import_questions_path, params: {topic_id: topic.id}

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Please attach a file")
      end
    end
  end
end
