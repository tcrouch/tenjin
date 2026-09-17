# frozen_string_literal: true

require "rails_helper"

RSpec.describe "School admin sets up classrooms", :default_creates, :js do
  let!(:classroom) { create(:classroom, school: school) }
  let!(:quiz_subject) { create(:subject) }

  before do
    sign_in school_admin
    visit(classrooms_path)
  end

  context "before a subject is set" do
    it "does not show a sync required message" do
      expect(page).to have_no_content("School sync required")
    end

    it "words the status as the admin table does" do
      expect(page).to have_css("#syncStatus", exact_text: "Synced")
    end
  end

  context "when a subject is set" do
    before { select quiz_subject.name, from: "subject" }

    it "shows a sync required message" do
      expect(page).to have_content("School sync required. Click here to start")
    end

    it "marks the status as needing a sync" do
      expect(page).to have_css("#syncStatus", exact_text: "Sync needed")
    end
  end
end
