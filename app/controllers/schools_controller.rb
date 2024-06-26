# frozen_string_literal: true

class SchoolsController < ApplicationController
  before_action :authenticate_admin!, only: %i[index new create update show show_stats]

  def index
    @schools = policy_scope(School).order(:name)
    @school_groups = policy_scope(SchoolGroup).order(:name)
  end

  def show_stats
    authorize current_admin
    @school_statistics = School::CompileSchoolStatistics.call
    @customisation_statistics = Customisation.select(:name, :customisation_type, "COUNT(customisations.id)")
      .left_joins(:customisation_unlocks)
      .group(:id)
      .order(count: :desc)
    render "overall_statistics"
  end

  def show
    @school = authorize find_school
    @school_statistics = School::CompileSchoolStatistics.call(@school)
    @school_admins = User.where(school: @school).with_role(:school_admin)
    @users = User.where(school: @school)
  end

  def new
    @school = School.new
    authorize @school
  end

  def create
    @school = School::AddSchool.call(school_params)
    if @school.persisted?
      authorize @school
      redirect_to @school
      SyncSchoolJob.perform_later @school
    else
      render :new
    end
  end

  def update
    school = authorize find_school
    school.update_attributes(update_school_params)
    return head :ok if request.xhr?

    redirect_to schools_path
  end

  def sync
    if current_admin.present?
      authenticate_admin!
    else
      authenticate_user!
    end

    school = authorize find_school
    school.update_attribute("sync_status", "queued")
    SyncSchoolJob.perform_later school
    redirect_to classrooms_path
  end

  def reset_all_passwords
    authorize find_school
    ResetUserPasswordsJob.perform_later(current_user)
    flash[:alert] = "Request received.  You will receive an email shortly with usernames and passwords."
    redirect_to users_path
  end

  private

  def find_school
    School.find(params[:id])
  end

  def school_params
    params.require(:school).permit(:client_id, :token)
  end

  def update_school_params
    params.require(:school).permit(:school_group_id, :permitted)
  end

  def reset_all_password_params
    params.permit(:reset_all)
  end
end
