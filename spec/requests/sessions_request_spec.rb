# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", :default_creates do
  describe "signing out" do
    before { sign_in student }

    it "disconnects the user's live leaderboard streams" do
      expect { delete destroy_user_session_path }
        .to have_broadcasted_to("action_cable/#{student.to_gid_param}").with(type: "disconnect", reconnect: false)
    end
  end
end
