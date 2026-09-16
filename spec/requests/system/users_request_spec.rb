# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::Users", :default_creates, type: :request do
  describe "GET /system/users/manage_roles" do
    before { sign_in super_admin }

    it "renders the manage_roles view" do
      get manage_roles_system_users_path
      expect(response).to have_http_status(:ok)
    end

    context "with a school selected" do
      let!(:teacher) { super() }

      before { get manage_roles_system_users_path(school: school) }

      it "renders every id once" do
        ids = Capybara.string(response.body).all("[id]").map { |element| element[:id] }
        expect(ids.tally.select { |_id, count| count > 1 }).to be_empty
      end

      it "leaves the role unchosen, so no click grants one by default" do
        expect(Capybara.string(response.body))
          .to have_css("select[name='user[role]'][required] option:first-child[value='']", exact_text: "Choose role…")
          .and have_no_css("select[name='user[role]'] option[selected]")
      end
    end
  end

  describe "PATCH /system/users/:id/set_role" do
    context "as a super admin" do
      before { sign_in super_admin }

      it "adds a role" do
        employee = create(:user, school: school, role: :employee)
        expect {
          patch set_role_system_user_path(employee), params: {user: {role: "school_admin"}}
        }.to change { employee.reload.has_role?(:school_admin) }.from(false).to(true)
      end

      context "with no role chosen" do
        before { patch set_role_system_user_path(teacher), params: {user: {role: ""}} }

        it "adds no role" do
          expect(teacher.reload.roles).to be_empty
        end

        it "explains the refusal" do
          expect(response).to redirect_to(manage_roles_system_users_path(school: school))
          expect(flash[:alert]).to eq("Role not found")
        end
      end

      it "does not allow roles to be added to students" do
        patch set_role_system_user_path(student), params: {user: {role: "school_admin", subject: school}}
        expect(response).to redirect_to(root_path)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "requires admin authentication" do
        patch set_role_system_user_path(teacher), params: {user: {role: "school_admin", subject: school}}
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe "DELETE /system/users/:id/remove_role" do
    before { sign_in super_admin }

    it "removes a role" do
      employee = create(:user, school: school, role: :employee)
      employee.add_role(:school_admin)
      expect {
        delete remove_role_system_user_path(employee), params: {user: {role: "school_admin"}}
      }.to change { employee.reload.has_role?(:school_admin) }.from(true).to(false)
    end
  end

  describe "PATCH /system/users/:id/update_email" do
    let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html, text/html"} }

    before { sign_in super_admin }

    it "updates the email" do
      employee = create(:user, school: school, role: :employee)
      patch update_email_system_user_path(employee), params: {user: {email: "new@example.com"}}, headers: turbo_headers
      expect(employee.reload.email).to eq("new@example.com")
    end
  end
end
