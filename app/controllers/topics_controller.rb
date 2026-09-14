# frozen_string_literal: true

class TopicsController < ApplicationController
  before_action :authenticate_user!

  def create
    subject = Subject.find(subject_id_param)
    topic = Topic.new(subject: subject, active: true, name: "New topic")
    authorize topic
    topic.save!

    redirect_to topic_questions_path(topic_id: topic)
  end

  def update
    topic = authorize find_topic
    topic.update(topic_params)
    head :no_content
  end

  def destroy
    topic = authorize find_topic

    topic.destroy
    redirect_to questions_path
  end

  private

  def find_topic
    Topic.find(params[:id])
  end

  def topic_params
    params.require(:topic).permit(:name, :default_lesson_id)
  end

  def subject_id_param
    params.require(:topic).require(:subject_id)
  end
end
