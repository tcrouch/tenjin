# frozen_string_literal: true

# Identifies each cable connection by the Warden session its handshake carries
class ApplicationCable::Connection < ActionCable::Connection::Base
  identified_by :current_user

  def connect
    self.current_user = find_verified_user
  end

  private

  def find_verified_user
    # Devise's fetch hooks log out and throw for an inactive user; a socket can only reject, so apply the rule here
    user = env["warden"].user(scope: :user, run_callbacks: false)
    return user if user&.active_for_authentication?

    reject_unauthorized_connection
  end
end
