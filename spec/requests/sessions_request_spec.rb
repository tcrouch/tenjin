# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", :default_creates do
  describe "signing in" do
    let(:disabled_student) { create(:student, school: school, disabled: true, password: "correct horse") }
    let(:credentials) { {user: {login: disabled_student.username, password: "correct horse"}} }

    it "refuses a disabled user" do
      post user_session_path, params: credentials
      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!
      expect(response.body).to include("Your account is no longer active")
    end

    it "refuses a disabled user arriving through Wonde" do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:wonde] =
        OmniAuth::AuthHash.new(provider: "wonde", uid: disabled_student.upi, info: {upi: disabled_student.upi})
      get user_wonde_omniauth_callback_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "an existing session" do
    before do
      sign_in student
      get dashboard_path
      student.update!(disabled: true)
    end

    it "ends once the user is disabled" do
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "signing out" do
    before { sign_in student }

    it "disconnects the user's live leaderboard streams" do
      expect { delete destroy_user_session_path }
        .to have_broadcasted_to("action_cable/#{student.to_gid_param}").with(type: "disconnect", reconnect: false)
    end
  end
end
