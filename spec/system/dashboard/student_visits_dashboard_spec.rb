# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Student visits the dashboard", :default_creates, :js do
  before do
    setup_subject_database
    sign_in student
  end

  it "shows the arrow for a tutorial"

  context "when looking at the challenges" do
    let!(:challenge_one) { create(:challenge, topic: topic, end_date: 1.hour.from_now) }
    let!(:challenge_two) { create(:challenge, topic: create(:topic, subject: subject)) }
    let!(:answer) { create(:answer, question: question, correct: true) }
    let(:second_subject) { create(:subject) }
    let(:second_topic) { create(:topic, subject: second_subject) }
    let(:progressed_challenge) { create(:challenge_progress, user: student, challenge: challenge_one, progress: 70) }
    let(:completed_challenge) do
      create(:challenge_progress, user: student,
        challenge: challenge_one, progress: 100, completed: true)
    end
    let(:challenge_css_selector) { "#challenge-table tr[data-topic='#{topic.id}']" }

    it "shows challenges for subjects" do
      visit(dashboard_path)
      expect(page).to have_content(challenge_one.stringify)
    end

    it "shows progress for full marks challenges" do
      progressed_challenge
      visit(dashboard_path)
      expect(page).to have_css("td", exact_text: progressed_challenge.progress)
    end

    it "shows challenge as complete if finished" do
      completed_challenge
      visit(dashboard_path)
      expect(page).to have_css("td svg.fa-check")
    end

    it "only shows challenges for enrolled subjects" do
      second_topic
      c = Challenge.create_challenge(second_subject)
      visit(dashboard_path)
      expect(page).to have_no_content(c.stringify)
    end

    it "navigates to the correct quiz when clicked" do
      visit(dashboard_path)
      find(:css, challenge_css_selector).click
      expect(page).to have_css("p", exact_text: challenge_one.topic.name)
    end

    it "allows answering a question after creating a quiz from a challenge" do # turbolinks bug
      visit(dashboard_path)
      find(:css, challenge_css_selector).click
      first(class: "question-button").click
      expect(page).to have_text("Next Question")
    end

    it "shows the student's challenge points in the nav bar" do
      student.update!(challenge_points: 25)
      visit(dashboard_path)
      expect(page).to have_css("p", exact_text: 25)
    end
  end

  context "when looking at homeworks" do
    let!(:homework) { create(:homework, classroom: classroom, topic: topic) }
    let(:homework_future) { create(:homework, due_date: 8.days.from_now, classroom: classroom) }
    let(:lesson) { create(:lesson, subject: classroom.subject) }
    let(:homework_lesson) { create(:homework, due_date: 8.days.from_now, classroom: classroom, lesson: lesson) }

    it "shows current homework assignments" do
      visit(dashboard_path)
      expect(page).to have_content(homework.topic.name).and have_content(homework.required)
    end

    it "limits homeworks owing to the last 15" do
      create_list(:homework_progress, 14, user: student, completed: false)
      visit(dashboard_path)
      expect(page).to have_css("tr.homework-row", count: 15)
    end

    it "shows completed homeworks with a cross (times) icon" do
      visit(dashboard_path)
      expect(page).to have_css(".homework-row[data-homework='#{homework.id}'] > td:last-child > svg.fa-times")
    end

    it "shows completed homeworks with a tick icon" do
      HomeworkProgress.where(homework: homework, user: student).first.update_attribute(:completed, true)
      visit(dashboard_path)
      expect(page).to have_css(".homework-row[data-homework='#{homework.id}'] > td:last-child > svg.fa-check")
    end

    it "shows overdue homeworks with an exclamation icon" do
      homework.update_attribute(:due_date, 1.day.ago)
      visit(dashboard_path)
      expect(page).to have_css(".homework-row[data-homework='#{homework.id}'] > td:last-child > svg.fa-exclamation")
    end

    it "shows homeworks completed in the last week only" do
      HomeworkProgress.where(homework: homework, user: student).first.update_attribute(:completed, true)
      homework.update_attribute(:due_date, 2.weeks.ago)
      visit(dashboard_path)
      expect(page).to have_no_css(".homework-row[data-homework='#{homework.id}']")
    end

    it "shows the homeworks in date order" do
      homework_future
      visit(dashboard_path)
      expect(page).to have_css(".homework-row:first-child[data-homework='#{homework.id}']")
    end

    it "navigates to the correct quiz when clicked" do
      answer
      visit(dashboard_path)
      find(".homework-row").click
      expect(page).to have_css("p", exact_text: homework.topic.name)
    end

    it "shows the lesson if a lesson based homework" do
      homework_lesson
      visit(dashboard_path)
      expect(page).to have_content(homework_lesson.lesson.title)
    end

    it "navigates to a lesson quiz when clicked" do
      homework_lesson
      create_list(:question, 10, lesson: homework_lesson.lesson, topic: homework_lesson.lesson.topic)
      visit(dashboard_path)
      find(".homework-row", text: homework_lesson.lesson.title).click
      expect(page).to have_css("p", exact_text: homework_lesson.lesson.title)
    end

    it "stops points being added on third lesson attempt"
    it "prevents you taking a lesson homework that has already been completed"

    it "only shows homeworks for the current teacher" do
      create(:homework)
      visit(dashboard_path)
      expect(page).to have_css("tr.homework-row", count: 1)
    end
  end
end
