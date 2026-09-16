# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::Customisations", :default_creates, type: :request do
  let(:school_group_admin) { create(:school_group_admin) }

  describe "GET /system/customisations" do
    let!(:customisation) { create(:customisation) }

    before do
      sign_in admin
      get system_customisations_path
    end

    context "as a super admin" do
      let(:admin) { super_admin }

      it "offers the admin controls rather than the shop" do
        expect(Capybara.string(response.body))
          .to have_link("Edit", href: edit_system_customisation_path(customisation))
          .and have_no_button("Buy")
      end
    end

    context "as a school group admin" do
      let(:admin) { school_group_admin }

      it { expect(response).to redirect_to(root_path) }
    end
  end

  describe "admin route protection" do
    before do
      sign_in student
      get system_customisations_path
    end

    it "redirects users to the admin login" do
      expect(response).to redirect_to(new_admin_session_path)
    end
  end

  describe "POST /system/customisations" do
    before { sign_in super_admin }

    it "creates a customisation" do
      expect {
        post system_customisations_path, params: {
          customisation: {
            name: "Test Customisation",
            value: "blue,heart",
            customisation_type: "leaderboard_icon",
            cost: 5,
            purchasable: true
          }
        }
      }.to change(Customisation, :count).by(1)
    end

    it "does not create a customisation with a blank name" do
      expect {
        post system_customisations_path, params: {
          customisation: {name: "", value: "blue,heart", customisation_type: "leaderboard_icon", cost: 5}
        }
      }.not_to change(Customisation, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(Capybara.string(response.body)).to have_css("h1", exact_text: "Add Customisation")
        .and have_css("form .invalid-feedback", exact_text: "Name can't be blank")
        .and have_text("Name can't be blank", count: 1)
    end
  end

  describe "PATCH /system/customisations/:id" do
    before { sign_in super_admin }

    it "updates a customisation" do
      customisation = create(:customisation)
      patch system_customisation_path(customisation), params: {
        customisation: {name: "Renamed"}
      }
      expect(customisation.reload.name).to eq("Renamed")
    end

    it "does not save an invalid name" do
      customisation = create(:customisation, name: "Original")
      patch system_customisation_path(customisation), params: {
        customisation: {name: ""}
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(customisation.reload.name).to eq("Original")
      expect(Capybara.string(response.body)).to have_css("h1", exact_text: "Edit Original")
    end
  end
end
