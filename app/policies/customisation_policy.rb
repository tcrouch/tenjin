# frozen_string_literal: true

class CustomisationPolicy < ApplicationPolicy
  def index?
    user.super?
  end

  alias_method :show?, :index?
  alias_method :edit?, :index?
  alias_method :update?, :index?
  alias_method :new?, :index?
  alias_method :create?, :index?

  class Scope < Scope
    def resolve
      return scope.all if user.super?
    end
  end
end
