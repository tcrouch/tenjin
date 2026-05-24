# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Teacher sets homework", :default_creates, :js do
  let(:classroom) { create(:classroom, subject: subject, school: teacher.school) }
  let(:flatpickr_one_week_from_now) do
    "span.flatpickr-day[aria-label=\"#{1.week.from_now.strftime("%B %-e, %Y")}\"]"
  end
  let!(:topic) { create(:topic, subject: subject) }
  let(:lesson) { create(:lesson, topic: topic) }

  before do
    sign_in teacher
    setup_subject_database
    create(:enrollment, classroom: classroom, user: teacher)
  end

  context "when creating a homework" do
    it "creates a homework" do
      visit(new_homework_path(classroom: {classroom_id: classroom.id}))
      create_homework
      click_button("Set Homework")
      expect(page).to have_css("#flash-notice", text: "homework set")
    end

    it "attaches the homework to the correct classroom" do
      visit(new_homework_path(classroom: {classroom_id: classroom.id}))
      create_homework
      click_button("Set Homework")
      expect(page).to have_content(classroom.name)
    end

    it "redirects when no classroom is specified" do
      visit(new_homework_path)
      expect(page).to have_current_path(dashboard_path)
    end
  end

  context "when viewing a homework" do
    let(:homework) { create(:homework, classroom: classroom) }

    before do
      create_list(:enrollment, 9, classroom: classroom)
      visit(homework_path(homework))
    end

    it "shows all the students that are assigned to the homework" do
      expect(page).to have_css("tr.student-row", count: 10)
    end

    it "shows the percentage of students that have completed the homework" do
      HomeworkProgress.first.update_attribute(:completed, true)
      visit(homework_path(homework))
      expect(page).to have_content("10%")
    end

    it "allows the teacher to delete the homework" do
      click_link("Delete Homework")
      expect(page).to have_current_path(classroom_path(classroom))
    end

    it "shows the progress towards completion" do
      HomeworkProgress.first.update_attribute(:progress, 50)
      visit(homework_path(homework))
      expect(page).to have_content("50%")
    end
  end

  context "when setting a lesson homework" do
    let!(:lesson) { create(:lesson, topic: topic) }
    let(:question_count) { 10 }
    let!(:questions) { create_list(:question, question_count, lesson: lesson, topic: lesson.topic) }

    context "with fewer than 10 questions" do
      let(:question_count) { 9 }

      it "does not list the lesson" do
        visit(new_homework_path(classroom: {classroom_id: classroom.id}))
        select topic.name, from: "Topic"
        expect(page).to have_no_content(lesson.title)
      end
    end

    it "creates a lesson-specific homework" do
      visit(new_homework_path(classroom: {classroom_id: classroom.id}))
      create_homework_for_lesson
      click_button("Set Homework")
      expect(page).to have_css("#flash-notice", text: "homework set")
    end

    it "only shows lessons when a topic has been selected" do
      visit(new_homework_path(classroom: {classroom_id: classroom.id}))
      expect(page).to have_no_content(lesson.title)
    end

    context "when a topic has been selected" do
      let!(:lesson_different_topic) do
        other_topic = create(:topic, subject: subject)
        other_lesson = create(:lesson, topic: other_topic)
        create_list(:question, question_count, lesson: other_lesson, topic: other_topic)
        other_lesson
      end

      before do
        visit(new_homework_path(classroom: {classroom_id: classroom.id}))
        select topic.name, from: "Topic"
      end

      it "only shows lessons for the topic selected" do
        expect(page).to have_no_content(lesson_different_topic.title)
      end
    end
  end

  context "when viewing a homework for a lesson" do
    let!(:questions) { create_list(:question, 10, lesson: lesson, topic: lesson.topic) }

    before do
      visit(new_homework_path(classroom: {classroom_id: classroom.id}))
      create_homework_for_lesson
      click_button "Set Homework"
      find_by_id("flash-notice") # homework view page
    end

    it "shows the lesson the homework was created for if available" do
      expect(page).to have_content(lesson.title)
    end

    it "shows the topic the lesson was created for" do
      expect(page).to have_content(topic.name)
    end
  end
end
