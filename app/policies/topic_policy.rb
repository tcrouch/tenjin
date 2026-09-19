# frozen_string_literal: true

class TopicPolicy < ApplicationPolicy
  # Also used to authorize editing questions for a topic

  class Scope < Scope
    def resolve
      scope.where(active: true, subject: Subject.authored_by(user, :question_author).where(active: true))
    end
  end

  def update?
    user.has_role? :question_author, record.subject
  end

  alias_method :create?, :update?
  alias_method :destroy?, :update?
  alias_method :show?, :update?
end
