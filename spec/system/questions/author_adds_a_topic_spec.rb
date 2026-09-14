# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Author adds a topic", :default_creates do
  let(:author) { create(:question_author, subject: quiz_subject) }

  before do
    sign_in author
    visit(questions_path)
  end

  # rack_test form-wiring smoke; TopicsController#create is covered in spec/requests/topics_request_spec.rb
  it "lands on the new topic ready to be renamed" do
    click_button "Add Topic"
    expect(page).to have_field("Topic Name:", with: "New topic")
  end
end
