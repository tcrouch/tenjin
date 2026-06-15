# frozen_string_literal: true

class Quiz < ApplicationRecord
  LUCKY_DIP = "Lucky Dip"

  belongs_to :user
  belongs_to :subject
  belongs_to :topic, optional: true
  belongs_to :lesson, optional: true

  has_many :asked_questions
  has_many :questions, through: :asked_questions
  attr_accessor :picked_subject

  after_create :update_usage_statistics

  scope :for_user, ->(user) { where(user: user) }

  def self.current_for(user)
    quizzes = for_user(user)
    return nil if quizzes.empty?
    return quizzes.first if quizzes.count == 1

    deactivate_stale_for(user)
    quizzes.where(active: true).first
  end

  def self.deactivate_stale_for(user)
    for_user(user).order(created_at: :desc).drop(1).each do |quiz|
      if quiz.num_questions_asked.zero?
        quiz.delete
      else
        quiz.update(active: false)
      end
    end
  end

  private

  def update_usage_statistics
    s = UsageStatistic.where(user: user, topic: topic, lesson: lesson, date: Date.current).first_or_create!
    s.increment!(:quizzes_started)
  end
end
