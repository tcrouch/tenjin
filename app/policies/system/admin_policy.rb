# frozen_string_literal: true

module System
  class AdminPolicy < System::ApplicationPolicy
    def show? = super?
    def new? = super?
    def manage_roles? = super?
    def reset_year? = super?
    # Only drops the admin's own user session, so no level applies
    def unbecome? = true
    def show_stats? = super? || school_group?
  end
end
