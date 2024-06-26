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
    it "does not succeed if I am an employee" do
      sign_in teacher
      reset_all_link
      expect(response).to redirect_to(root_path)
    end

    it "does not succeed if I am a student" do
      sign_in student
      reset_all_link
      expect(response).to redirect_to(root_path)
    end

    it "displays a flash notice if unsuccessful" do
      sign_in student
      reset_all_link
      expect(flash[:alert]).to be_present
    end
  end

  context "when managing roles" do
    it "only adds roles to employees" do
      sign_in super_admin
      student
      patch set_role_user_path(student, user: {role: "school_admin", subject: school})
      expect(response).to redirect_to(root_path)
    end

    it "only allows me to add roles if I am a super admin" do
      sign_in student
      patch set_role_user_path(teacher, user: {role: "school_admin", subject: school})
      expect(response).to redirect_to(new_admin_session_path)
    end
  end
end
