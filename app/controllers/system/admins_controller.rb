# frozen_string_literal: true

module System
  class AdminsController < BaseController
    # Typed to confirm a year reset, which deletes every school's classes
    RESET_YEAR_CONFIRMATION = "reset year"

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
      unless params[:confirmation] == RESET_YEAR_CONFIRMATION
        return redirect_to system_admin_path(current_admin), alert: "Type #{RESET_YEAR_CONFIRMATION} to confirm the reset"
      end

      ResetYearJob.perform_later
      redirect_to system_schools_path, notice: "Resetting year data: classes, challenges and leaderboards are being cleared"
    end

    private

    def become_admin_params
      params.require(:user_id)
    end
  end
end
