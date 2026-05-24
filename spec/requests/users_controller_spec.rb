# frozen_string_literal: true

require "rails_helper"

RSpec.describe "user controller", :default_creates do
  before do
    student
  end

  def reset_all_link
    patch reset_all_passwords_school_path(student.school)
  end

  context "when I am not authorized to perform this action" do
    it "redirects employees to the root path" do
      sign_in teacher
      reset_all_link
      expect(response).to redirect_to(root_path)
    end

    it "redirects students to the root path" do
      sign_in student
      reset_all_link
      expect(response).to redirect_to(root_path)
    end

    it "shows an alert flash message" do
      sign_in student
      reset_all_link
      expect(flash[:alert]).to be_present
    end
  end

  context "when managing roles" do
    it "does not allow roles to be added to students" do
      sign_in super_admin
      student
      patch set_role_user_path(student, user: {role: "school_admin", subject: school})
      expect(response).to redirect_to(root_path)
    end

    it "requires super admin authentication" do
      sign_in student
      patch set_role_user_path(teacher, user: {role: "school_admin", subject: school})
      expect(response).to redirect_to(new_admin_session_path)
    end
  end
end
