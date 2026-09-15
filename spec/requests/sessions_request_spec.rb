# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", :default_creates do
  before do
    sign_in student
    get leaderboard_path(quiz_subject.name)
  end

  it "keeps the leaderboard stream cookie while signed in" do
    expect(cookies[:user_id]).to be_present
  end

  context "when signed out" do
    before { delete destroy_user_session_path }

    it "clears the leaderboard stream cookie" do
      expect(cookies[:user_id]).to be_blank
    end
  end
end
