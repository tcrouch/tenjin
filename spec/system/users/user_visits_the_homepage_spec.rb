# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User visits the homepage", :default_creates, :js do
  describe "the login modal" do
    before { visit root_path }

    # Signing in itself is covered in spec/requests/sessions_request_spec.rb
    it "pops up the login form" do
      expect(page).to have_no_field("user_login")
      click_button "Login"
      expect(page).to have_field("user_login").and have_field("user_password")
    end
  end

  describe "the Google account link prompt" do
    # One Shepherd-tour smoke; which dashboards carry the marker that starts it, linked or
    # not, student or teacher, is covered in spec/requests/dashboard_request_spec.rb
    context "with an unlinked student account" do
      let(:unlinked_student) { create(:student, :no_oauth, school: school) }

      before do
        sign_in unlinked_student
        visit(dashboard_path)
      end

      it "prompts to link the account" do
        expect(page).to have_content("Let's get your account linked")
      end
    end
  end
end
