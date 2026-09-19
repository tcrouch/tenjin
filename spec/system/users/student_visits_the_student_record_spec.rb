# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Student visits their own user record", :default_creates, :js do
  before do
    sign_in student
    visit(user_path(student))
  end

  # The turbo_confirm smoke for this directory; the action and the link/unlink buttons it
  # swaps between are covered in spec/requests/users_request_spec.rb
  it "unlinks their Google account" do
    page.accept_confirm { click_button "Unlink #{student.oauth_email}" }
    expect(page).to have_css("#loginGoogle")
  end
end
