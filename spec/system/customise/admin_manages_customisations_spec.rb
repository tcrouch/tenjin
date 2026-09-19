# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin manages customisations", :default_creates do
  before do
    sign_in super_admin
    visit new_system_customisation_path
  end

  # rack_test form-wiring smoke: the type select is the one input a request spec cannot pin, so the
  # card must land among the leaderboard icons. State assertions live in
  # spec/requests/system/customisations_request_spec.rb
  it "creates a leaderboard icon" do
    select "Leaderboard icon", from: "customisation_customisation_type"
    fill_in("Name", with: "Golden Trophy")
    fill_in("Value", with: "gold,trophy")
    fill_in("Cost", with: "200")
    click_button("Create Customisation")
    expect(page).to have_css("section.icons .card", text: "Golden Trophy")
  end
end
