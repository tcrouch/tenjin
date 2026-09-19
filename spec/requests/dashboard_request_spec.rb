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

    # The hidden #oAuthEmail input is what starts the "link your account" tour in the browser
    describe "the Google account link prompt" do
      context "with an unlinked student account" do
        let(:unlinked_student) { create(:student, :no_oauth, school: school) }

        before do
          sign_in unlinked_student
          get dashboard_path
        end

        it "marks the page for the prompt" do
          expect(Capybara.string(response.body)).to have_css("#oAuthEmail", visible: :all)
        end
      end

      context "with a linked student account" do
        before do
          sign_in student
          get dashboard_path
        end

        it "does not mark the page for the prompt" do
          expect(Capybara.string(response.body)).to have_no_css("#oAuthEmail", visible: :all)
        end
      end

      context "with an unlinked teacher account" do
        let(:unlinked_teacher) { create(:teacher, :no_oauth, school: school) }

        before do
          sign_in unlinked_teacher
          get dashboard_path
        end

        it "marks the page for the prompt" do
          expect(Capybara.string(response.body)).to have_css("#oAuthEmail", visible: :all)
        end
      end

      context "with a linked teacher account" do
        it "does not mark the page for the prompt"
      end
    end
  end
end
