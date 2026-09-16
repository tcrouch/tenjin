# frozen_string_literal: true

require "rails_helper"

# confirm-text smoke; System::AdminsController#reset_year is covered in
# spec/requests/system/admins_request_spec.rb
RSpec.describe "Super resets year data", :default_creates, :js do
  before do
    sign_in super_admin
    visit system_admin_path(super_admin)
  end

  it "keeps the reset disabled until the confirmation is typed" do
    expect(page).to have_button("Reset Year Data", disabled: true)
    fill_in "Type reset year to confirm", with: "reset year"
    click_button "Reset Year Data"
    expect(page).to have_css(".alert", text: "Resetting year data")
  end
end
