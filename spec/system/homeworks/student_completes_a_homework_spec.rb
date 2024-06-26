# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Student completes a homework", :default_creates, :js do
  before do
    setup_subject_database
    sign_in student
  end

  context "when looking at the challenges" do
    let(:homework_ten_percent) { create(:homework, topic: topic, classroom: classroom, required: 10) }
    let(:quiz) { create(:new_quiz) }

    before do
      homework_ten_percent
      answer
    end

    it "lets me complete a homework" do
      visit(dashboard_path)
      find(:css, ".homework-row[data-homework='#{homework_ten_percent.id}']").click
      first(class: "question-button").click
      first(class: "next-button").click
      expect(page).to have_css(".homework-row > td > svg.fa-check")
    end
  end

  context "when completing a lesson homework" do
    let(:lesson) { create(:lesson, topic: topic) }
    let(:homework_with_lesson) do
      create(:homework, lesson: lesson, topic: lesson.topic, classroom: classroom, required: 10)
    end
    let(:homework_progress_complete) { create(:homework_progress, user: student, homework: homework, completed: true) }

    before do
      homework_with_lesson
      create_list(:question, 10, topic: lesson.topic, lesson: lesson)
    end

    it "only gives questions assigned to that lesson" do
      visit(dashboard_path)
      find(:css, ".homework-row[data-homework='#{homework_with_lesson.id}']").click
      expect(page).to have_css("#quiz-name", exact_text: lesson.title)
    end

    it "only awards points for the first attempt" do
      create(:usage_statistic, lesson: lesson, topic: lesson.topic, user: student, quizzes_started: 1,
        date: Date.current)
      visit(dashboard_path)
      find(:css, ".homework-row[data-homework='#{homework_with_lesson.id}']").click
      find(:css, ".trix-content")
      expect(page).to have_content("This quiz is currently not counting towards your leaderboard points")
    end
  end
end
