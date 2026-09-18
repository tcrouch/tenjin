# frozen_string_literal: true

class Subject < ApplicationRecord
  resourcify

  has_many :classrooms
  has_many :lessons
  has_many :quizzes
  has_many :topics

  # rolify's finder joins roles, so it repeats a subject per matching role and
  # selects subjects.*, which no subquery can take. Roles granted on the Subject
  # class rather than a subject do not count.
  scope :authored_by, ->(user, role) {
    where(id: user.roles.where(name: role, resource_type: "Subject").select(:resource_id))
  }

  validates :name, presence: true, uniqueness: true

  def flagged_questions
    Question.joins(:topic)
      .includes(:question_statistic, :lesson, :rich_text_question_text)
      .where(topics: {subject: id})
      .where(flagged_questions_count: 1..)
      .where(active: true)
      .order(flagged_questions_count: :desc)
      .limit(20)
  end
end
