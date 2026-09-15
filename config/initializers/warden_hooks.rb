# frozen_string_literal: true

# Sockets already identified as the user would otherwise keep streaming after sign-out
Warden::Manager.before_logout(scope: :user) do |user, warden, _options|
  ActionCable.server.remote_connections.where(current_user: user).disconnect(reconnect: false) if user
end
