# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", :default_creates do
  describe "signing out" do
    before do
      cookies[:user_id] = "stale"
      sign_in student
    end

    it "clears the leaderboard stream cookie" do
      delete destroy_user_session_path
      expect(cookies[:user_id]).to be_blank
    end
  end
end
