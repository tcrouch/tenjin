# frozen_string_literal: true

class SubjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def update?
    user.super?
  end

  def flagged_questions?
    user.has_role? :question_author, record
  end

  alias_method :create?, :update?
  alias_method :destroy?, :update?
  alias_method :show?, :update?
  alias_method :new?, :update?
end
