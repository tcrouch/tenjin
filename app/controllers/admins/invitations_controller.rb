# frozen_string_literal: true

class Admins::InvitationsController < Devise::InvitationsController
  before_action :authenticate_admin!

  def new
    authorize current_admin, policy_class: System::AdminPolicy
    super
  end

  private

  def invite_resource
    super { |admin| admin.role = "school_group" }
  end

  def after_accept_path_for(_resource)
    system_subjects_path
  end
end
