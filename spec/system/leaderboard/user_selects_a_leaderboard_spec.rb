# frozen_string_literal: true

require "rails_helper"
require "support/api_data"

RSpec.describe "User selects a leaderboard", :default_creates, :js do
  before do
    setup_subject_database
    sign_in student
  end

  context "when selecting a leaderboard to view" do
    let(:second_subject) { create(:subject) }
    let(:second_classroom) { create(:classroom, subject: second_subject, school: school) }

    before do
      topic
      create(:enrollment, classroom: second_classroom, user: student)
      visit leaderboard_index_path
    end

    it "lets me pick the topic for a subject" do
      click_link(subject.name)
      click_link(topic.name)
      expect(page).to have_css("h1", text: topic.name)
    end

    it "lets me pick the overall score for the subject" do
      click_link(subject.name)
      click_link("All")
      expect(page).to have_css("h1", text: subject.name)
    end

    it "lets me pick from multiple subjects" do
      click_link(second_subject.name)
      click_link("All")
      expect(page).to have_css("h1", text: second_subject.name)
    end
  end

  context "when the leaderboard has been loaded" do
    before do
      create(:topic_score, user: student, topic: topic)
      visit leaderboard_index_path
    end

    it "highlights the current user" do # javascript/turbolinks bug
      click_link(subject.name)
      click_link("All")
      expect(page).to have_css("tr.current-user")
    end
  end
end
