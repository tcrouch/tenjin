# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User attempts a challenge", :default_creates, :js do
  let!(:challenge) do
    create(:challenge, topic: topic, challenge_type: "number_correct", number_required: 1)
  end
  let!(:question) { create(:question, topic: topic) }

  before do
    setup_subject_database
    sign_in student
    visit(dashboard_path)
  end

  it "flags the challenge complete after the student finishes the quiz" do
    find("#challenge-table tbody tr:nth-child(1)").click
    find(".question-button").click
    find(".next-button").click
    expect(page).to have_css(".fa-check")
  end
end
