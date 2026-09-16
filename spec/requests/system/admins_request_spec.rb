# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::Admins", :default_creates, type: :request do
  before { sign_in super_admin }

  describe "GET /system/admins/:id" do
    it "renders the admin show page" do
      get system_admin_path(super_admin)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /system/admins/:id/become" do
    before { post become_system_admin_path(super_admin, user_id: student.id) }

    it "signs in as the target user and redirects to root" do
      expect(response).to redirect_to(root_url)
    end

    it "keeps the admin signed in" do
      get system_schools_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /system/admins/:id/become" do
    let(:admin) { super_admin }

    before do
      sign_in admin
      post become_system_admin_path(admin, user_id: student.id)
      delete become_system_admin_path(admin)
    end

    it "returns to the admin area and says who was signed out" do
      expect(response).to redirect_to(system_root_path)
      expect(flash[:notice]).to eq("Signed out #{student.full_name}")
    end

    it "ends the user session" do
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "keeps the admin signed in" do
      get system_schools_path
      expect(response).to have_http_status(:ok)
    end

    describe "as a school group admin" do
      let(:admin) { create(:school_group_admin) }

      it "returns to the admin area" do
        expect(response).to redirect_to(system_root_path)
      end
    end
  end

  describe "the impersonation banner" do
    context "after becoming a user" do
      before { post become_system_admin_path(super_admin, user_id: student.id) }

      it "names the user on their pages, under the user nav, with a way back to the admin area" do
        get dashboard_path
        expect(Capybara.string(response.body))
          .to have_css("#impersonation", text: "Viewing as #{student.full_name}")
          .and have_link("Admin area", href: system_root_path)
          .and have_button("Stop viewing")
          .and have_css("#current_user")
          .and have_no_link("Schools", href: system_schools_path)
      end

      it "names the user on admin pages, under the admin nav, with a way back to them" do
        get system_schools_path
        expect(Capybara.string(response.body))
          .to have_css("#impersonation", text: "Also signed in as #{student.full_name}")
          .and have_link("Back to their pages", href: dashboard_path)
          .and have_button("Sign them out")
          .and have_link("Schools", href: system_schools_path)
          .and have_no_css("#current_user")
      end
    end

    context "without becoming a user" do
      it "is absent from admin pages" do
        get system_schools_path
        expect(Capybara.string(response.body)).to have_no_css("#impersonation")
      end

      describe "as a student" do
        before do
          sign_out super_admin
          sign_in student
        end

        it "is absent from their pages" do
          get dashboard_path
          expect(Capybara.string(response.body)).to have_no_css("#impersonation")
        end
      end
    end
  end

  describe "POST /system/admins/:id/reset_year" do
    context "with the confirmation typed" do
      let(:params) { {confirmation: "reset year"} }

      it "schedules ResetYearJob" do
        expect {
          post reset_year_system_admin_path(super_admin), params: params
        }.to have_enqueued_job(ResetYearJob)
      end

      it "redirects to system_schools_path" do
        post reset_year_system_admin_path(super_admin), params: params
        expect(response).to redirect_to(system_schools_path)
        expect(flash[:notice]).to start_with("Resetting year data")
      end
    end

    context "with the confirmation mistyped" do
      let(:params) { {confirmation: "reset"} }

      it "schedules nothing" do
        expect {
          post reset_year_system_admin_path(super_admin), params: params
        }.not_to have_enqueued_job(ResetYearJob)
      end

      it "returns to the admin page and says why" do
        post reset_year_system_admin_path(super_admin), params: params
        expect(response).to redirect_to(system_admin_path(super_admin))
        expect(flash[:alert]).to eq("Type reset year to confirm the reset")
      end
    end
  end
end
