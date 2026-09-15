# frozen_string_literal: true

# ApplicationCable::Connection signs in from this cookie, which Devise's session reset leaves behind
Warden::Manager.before_logout(scope: :user) do |_user, warden, _options|
  warden.cookies.delete(:user_id)
end
