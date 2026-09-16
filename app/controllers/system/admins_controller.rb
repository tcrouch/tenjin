# frozen_string_literal: true

module System
  class AdminsController < BaseController
    def become
      user = User.find(become_admin_params)
      authorize user

      sign_in(:user, user)
      redirect_to root_url
    end

    def unbecome
      authorize current_admin
      user = current_user
      sign_out(:user)
      redirect_to system_root_path, notice: ("Signed out #{user.full_name}" if user)
    end

    def show
      authorize current_admin
    end

    def reset_year
      authorize current_admin
      ResetYearJob.perform_later
      flash[:alert] = "Reset Year Data"
      redirect_to system_schools_path
    end

    private

    def become_admin_params
      params.require(:user_id)
    end
  end
end
