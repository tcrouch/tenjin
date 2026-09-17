# frozen_string_literal: true

require "rails_helper"

RSpec.describe "dashboard controller", :default_creates do
  describe "GET #show" do
    describe "as a teacher" do
      before do
        create(:enrollment, classroom: classroom, user: teacher)
        sign_in teacher
        get dashboard_path
      end

      it "shows a link to the classrooms" do
        expect(Capybara.string(response.body)).to have_link("Classrooms", href: dashboard_path)
      end

      it "holds the page, but not the navbar, in the main landmark" do
        expect(Capybara.string(response.body)).to have_css("main")
          .and have_no_css("main #navbar-main")
      end

      it "does not show a link to school admin" do
        expect(Capybara.string(response.body)).to have_no_link("User Admin", href: users_path)
      end
    end

    describe "as a school admin" do
      before do
        create(:enrollment, classroom: classroom, user: school_admin)
        sign_in school_admin
        get dashboard_path
      end

      it "shows a link to the classrooms" do
        expect(Capybara.string(response.body)).to have_link("Classrooms", href: dashboard_path)
      end

      it "shows a link to school admin" do
        expect(Capybara.string(response.body)).to have_link("User Admin", href: users_path)
      end
    end
  end
end
