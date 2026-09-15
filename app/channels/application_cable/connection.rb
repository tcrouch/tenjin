# frozen_string_literal: true

# Identifies each cable connection by the Warden session its handshake carries
class ApplicationCable::Connection < ActionCable::Connection::Base
  identified_by :current_user

  def connect
    self.current_user = find_verified_user
  end

  private

  def find_verified_user
    env["warden"].user(:user) || reject_unauthorized_connection
  end
end
