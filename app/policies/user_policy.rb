# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(school: user.school, disabled: false)
    end
  end

  def index?
    user.has_role?(:school_admin)
  end

  def show?
    return true if user.has_role?(:school_admin) && user_in_same_school
    return true if user.employee? && user_in_same_school && record.student?

    user == record
  end

  def update?
    (user.employee? && record.school == user.school) || (record == user)
  end

  def destroy?
    return false if user == record

    user.has_role?(:school_admin)
  end

  def become?
    user.super? || user.school_group?
  end

  def set_role?
    user.super? && record.employee?
  end

  alias_method :remove_role?, :set_role?
  alias_method :update_email?, :set_role?
  alias_method :send_welcome_email?, :set_role?

  alias_method :reset_password?, :show?
  alias_method :unlink_oauth_account?, :show?

  private

  def user_in_same_school
    user.school == record.school
  end
end
