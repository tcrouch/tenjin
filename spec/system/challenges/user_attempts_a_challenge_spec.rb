# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User attempts a challenge", :default_creates, :js do
  before do
    setup_subject_database
    sign_in student
  end

  def click_through_quiz
    first(class: "question-button").click
    first(class: "next-button").click
    first(class: "question-button").click
    first(class: "next-button").click
  end

  context "when completing a number of questions challenge" do
    let!(:challenge) do
      create(:challenge, topic: topic, challenge_type: "number_correct",
        number_required: 1, end_date: 1.hour.from_now)
    end
    let!(:question) { create(:question, topic: topic) }

    it "flags the challenge complete" do
      visit(dashboard_path)
      find(:css, "#challenge-table tbody tr:nth-child(1)").click
      first(class: "question-button").click
      first(class: "next-button").click
      expect(page).to have_css("svg.fa-check")
    end
  end

  context "when completing a streak challenge" do
    let!(:challenge) do
      create(:challenge, topic: topic, challenge_type: "streak",
        number_required: 1, end_date: 1.hour.from_now)
    end
    let!(:question) { create(:question, topic: topic) }

    it "flags the challenge complete" do
      visit(dashboard_path)
      find(:css, "#challenge-table tbody tr:nth-child(1)").click
      first(class: "question-button").click
      first(class: "next-button").click
      expect(page).to have_css("svg.fa-check")
    end
  end

  context "when completing a num. points challenge" do
    let!(:challenge) do
      create(:challenge, topic: topic, challenge_type: "number_of_points",
        number_required: 1, end_date: 1.hour.from_now)
    end
    let!(:question) { create(:question, topic: topic) }

    it "navigates to the correct quiz when clicked" do
      visit(dashboard_path)
      find(:css, "#challenge-table tbody tr:nth-child(1)").click
      expect(page).to have_css("p", exact_text: challenge.topic.name)
    end

    it "allows answering a question after creating a quiz from a challenge" do # turbolinks bug
      visit(dashboard_path)
      find(:css, "#challenge-table tbody tr:nth-child(1)").click
      first(class: "question-button").click
      expect(page).to have_text("Next Question")
    end

    it "flags the challenge complete" do
      visit(dashboard_path)
      find(:css, "#challenge-table tbody tr:nth-child(1)").click
      first(class: "question-button").click
      first(class: "next-button").click
      expect(page).to have_css("svg.fa-check")
    end
  end

  context "when completing a daily challenge" do
    let!(:challenge) do
      create(:challenge, challenge_type: "number_of_points", daily: true, topic: topic,
        number_required: 1, end_date: 1.hour.from_now)
    end

    it "flags the challenge complete" do
      create(:question, topic: create(:topic, subject: quiz_subject))
      visit(dashboard_path)
      find(:css, "#challenge-table tbody tr:nth-child(1)").click
      click_through_quiz
      expect(page).to have_css("svg.fa-check")
    end

    it "only increases points for this student" do
      second_enrollment = create(:enrollment, classroom: classroom)
      create(:question, topic: create(:topic, subject: quiz_subject))
      visit(dashboard_path)
      find(:css, "#challenge-table tbody tr:nth-child(1)").click
      click_through_quiz
      sign_out student
      sign_in second_enrollment.user
      visit(dashboard_path)
      expect(page).to have_no_css(".fa-check")
    end
  end
end
