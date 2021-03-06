# frozen_string_literal: true

class ClassroomPolicy < ApplicationPolicy
  def show?
    user.employee?
  end

  def update?
    user.has_role?(:school_admin) && @record.school == user.school
  end

  class Scope < Scope
    def resolve
      scope.where(school: user.school)
    end
  end
end
