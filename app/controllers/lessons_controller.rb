# frozen_string_literal: true

class LessonsController < ApplicationController
  before_action :authenticate_user!

  def index
    @author = current_user.has_role? :lesson_author, :any

    set_permitted_lessons_and_subjects

    @subjects = Subject.joins(topics: :lessons).where(lessons: @lessons).distinct
  end

  def new
    subject = Subject.find(new_lesson_params)
    @topics = topics_for(subject)
    return redirect_to lessons_path, flash: {error: "No topics found for subject"} if @topics.empty?

    @lesson = Lesson.new(topic: @topics.first)
    authorize @lesson
  end

  def edit
    @lesson = find_lesson
    @topics = topics_for(@lesson.subject)
    authorize @lesson
  end

  def create
    @lesson = Lesson.new(lesson_params)
    authorize @lesson
    save_lesson
  end

  def update
    @lesson = authorize find_lesson
    @lesson.assign_attributes(lesson_params)
    save_lesson
  end

  def destroy
    lesson = authorize find_lesson
    lesson.destroy
    redirect_to lessons_path
  end

  private

  def find_lesson
    Lesson.find(params[:id])
  end

  # One query for new, edit and the invalid re-render: TopicPolicy scopes by
  # question_author, a role a lesson author need not hold.
  def topics_for(subject)
    Topic.where(active: true, subject: subject).order(:name)
  end

  def save_lesson
    unless @lesson.valid?
      @topics = topics_for(@lesson.subject)

      return render :edit if @lesson.persisted?

      return render :new
    end

    @lesson.save!

    redirect_to lessons_path
  end

  def new_lesson_params
    params.require(:subject)
  end

  def lesson_params
    params.require(:lesson).permit(:title, :video_link, :topic_id, :category)
  end

  def set_permitted_lessons_and_subjects
    if @author
      @editable_subjects = Subject.with_role(:lesson_author, current_user)
      @lessons = policy_scope(Lesson)
        .or(Lesson
                  .includes(:topic)
                  .where(topics: {subject: @editable_subjects.pluck(:id)})).order("topics.name, lessons.title")
    else
      @lessons = policy_scope(Lesson).includes(:topic).order("topics.name, lessons.title")
    end
  end
end
