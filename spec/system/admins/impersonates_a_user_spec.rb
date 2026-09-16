# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin impersonates a user", :default_creates, :js do
  let(:school_group_admin) { create(:school_group_admin) }

  shared_examples "an impersonator" do
    context "when impersonating a student" do
      let!(:student) { create(:student, school: school) }
      before { visit(system_school_path(school)) }

      it "signs in as the student" do
        click_button "Become User"
        expect(page).to have_css("#current_user", text: student.full_name)
      end
    end

    context "when impersonating a school admin" do
      let!(:school_admin) { create(:school_admin, school: school) }
      before { visit(system_school_path(school)) }

      it "signs in as the school admin" do
        within("#schoolAdminTable") { click_button "Become User" }
        expect(page).to have_css("#current_user", text: school_admin.full_name)
      end
    end
  end

  describe "as a super admin" do
    before { sign_in super_admin }
    include_examples "an impersonator"
  end

  describe "as a school group admin" do
    before { sign_in school_group_admin }
    include_examples "an impersonator"
  end

  describe "stopping" do
    let!(:student) { super() }

    before do
      sign_in super_admin
      visit(system_school_path(school))
      click_button "Become User"
    end

    it "returns to the admin area and ends the user session" do
      click_button "Stop viewing"
      expect(page).to have_text("Signed out #{student.full_name}")
        .and have_no_css("#impersonation")
    end
  end
end
