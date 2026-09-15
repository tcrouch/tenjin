# frozen_string_literal: true

# ApplicationCable::Connection signs in from this cookie, which Devise's session reset leaves behind
Warden::Manager.before_logout(scope: :user) do |user, warden, _options|
  warden.cookies.delete(:user_id)
  # Sockets already identified as the user would otherwise keep streaming after sign-out
  ActionCable.server.remote_connections.where(current_user: user).disconnect(reconnect: false) if user
end
