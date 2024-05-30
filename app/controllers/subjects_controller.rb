# frozen_string_literal: true

class SubjectsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @subjects = policy_scope(Subject).order(:name).where(active: true)
    @deactivated_subjects = Subject.where(active: false)
  end

  def new
    @subject = authorize Subject.new
  end

  def create
    @subject = authorize Subject.new(subject_params)

    if @subject.save
      redirect_to @subject
    else
      render :new
    end
  end

  def show
    @subject = authorize find_subject
  end

  def update
    @subject = authorize find_subject
    @subject.update(subject_params)
    redirect_to @subject
  end

  def destroy
    @subject = authorize find_subject
    @subject.update_attribute(:active, false)

    Enrollment.joins(:classroom).where(classrooms: { subject_id: @subject }).destroy_all
    Classroom.where(subject: @subject).update_all(subject_id: nil)
    redirect_to subjects_path
  end

  private

  def find_subject
    Subject.find(params[:id])
  end

  def subject_params
    params.require(:subject).permit(:name, :active)
  end
end
