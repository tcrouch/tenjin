# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize current_user, policy_class: DashboardPolicy # make it so that it checks if the school is permitted
    @subjects = current_user.subjects.uniq

    if current_user.student?
      @dashboard_style = find_dashboard_style
      @homework_progress = student_homework_progress
      student_challenges
      render "student_dashboard"
    else
      teacher_enrollments
      render "teacher_dashboard"
    end
  end

  private

  def student_homework_progress
    HomeworkProgress.includes(:homework, homework: [{topic: :subject}])
      .where("user_id = ? AND ( completed = false OR ( completed = true AND homeworks.due_date > ? )) ", current_user, 1.week.ago)
      .order("homeworks.due_date")
      .limit(15)
  end

  def student_challenges
    @challenges = Challenge.includes(topic: :subject)
      .where(topics: {subject: @subjects})
    @challenge_progresses = ChallengeProgress.where(challenge: @challenges).where(user: current_user).to_a
  end

  def teacher_enrollments
    @enrollments = Enrollment.includes(:classroom, :subject)
      .where(user: current_user)
    @other_classrooms = Classroom.where(school: current_user.school)
      .includes(:subject)
      .where.not(subject: nil)
      .where.not(id: @enrollments.select(:classroom_id))
  end
end
