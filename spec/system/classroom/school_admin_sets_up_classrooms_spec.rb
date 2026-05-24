# frozen_string_literal: true

require "rails_helper"

RSpec.describe "School admin sets up classrooms", :default_creates, :js do
  context "when configuring classrooms" do
    let!(:classroom) { create(:classroom, school: school) }
    let(:subject) { create(:subject) }

    before { sign_in school_admin }

    it "shows which classrooms have been retrieved from Wonde" do
      visit(classrooms_path)
      expect(page).to have_content(classroom.name)
    end

    it "allows setting a subject for the classroom" do
      subject
      visit(classrooms_path)
      select subject.name, from: "subject"
      visit(classrooms_path)
      expect(page).to have_content(subject.name)
    end

    it "links to the classroom setup page" do
      visit(classrooms_path)
      expect(page).to have_css("a", text: "Setup Classrooms")
    end

    it "shows a sync required message when a subject is set" do
      subject
      visit(classrooms_path)
      select subject.name, from: "subject"
      expect(page).to have_content("School sync required. Click here to start")
    end
  end
end
