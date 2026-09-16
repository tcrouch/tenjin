# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::Invitations", :default_creates, type: :request do
  before { sign_in super_admin }

  describe "GET /admins/invitation/new" do
    it "renders the invitation form via the System::InvitationsController" do
      get new_admin_invitation_path
      expect(response).to have_http_status(:ok)
      expect(controller.class).to eq(System::InvitationsController)
    end

    it "renders inside the admin area" do
      get new_admin_invitation_path
      expect(Capybara.string(response.body)).to have_css("#navbar-main a.nav-link", text: "Schools")
        .and have_title("Invite an Admin · Tenjin admin")
    end
  end
end
