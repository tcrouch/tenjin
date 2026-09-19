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

      it "says there are no retired customisations" do
        expect(Capybara.string(response.body)).to have_css(".retired-customisations", text: "No retired customisations.")
      end

      context "with dashboard styles in every state" do
        let!(:sticky_style) { create(:dashboard_customisation, name: "Aurora", sticky: true, purchasable: true) }
        let!(:available_style) { create(:dashboard_customisation, name: "Bramble", purchasable: true) }
        let!(:unavailable_style) { create(:dashboard_customisation, name: "Cobalt", purchasable: false) }
        let!(:retired_style) { create(:dashboard_customisation, name: "Dusk", retired: true) }

        before { get system_customisations_path }

        it "orders the cards sticky, then available, then unavailable" do
          section = Capybara.string(response.body).find("section.available-customisations .dashboard-styles")
          expect(section).to have_css(".dashboard-style", count: 3).and have_text(/Aurora.*Bramble.*Cobalt/m)
        end

        it "badges the sticky and unavailable cards" do
          page = Capybara.string(response.body)
          expect(page.find(".dashboard-style", text: "Aurora")).to have_text("Stickied")
          expect(page.find(".dashboard-style", text: "Bramble")).to have_no_text("Stickied").and have_no_text("Unavailable")
          expect(page.find(".dashboard-style", text: "Cobalt")).to have_text("Unavailable")
        end

        it "lists retired customisations in their own section" do
          expect(Capybara.string(response.body))
            .to have_css("section.retired-customisations .dashboard-style", text: "Dusk")
            .and have_no_css("section.available-customisations .dashboard-style", text: "Dusk")
        end
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

    it "creates a dashboard style with its image" do
      post system_customisations_path, params: {
        customisation: {
          name: "Aurora", value: "blue", customisation_type: "dashboard_style", cost: 200,
          image: fixture_file_upload("game-pieces.jpg", "image/jpeg")
        }
      }
      expect(response).to redirect_to(system_customisations_path)
      expect(flash[:notice]).to eq("Created new customisation Aurora")
      expect(Customisation.find_by!(name: "Aurora").image.filename.to_s).to eq("game-pieces.jpg")
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

    context "with a dashboard style" do
      let(:customisation) { create(:dashboard_customisation, purchasable: true) }

      it "updates the value, image and flags" do
        patch system_customisation_path(customisation), params: {
          customisation: {
            value: "blue", sticky: true, purchasable: false,
            image: fixture_file_upload("computer-science.jpg", "image/jpeg")
          }
        }
        expect(customisation.reload).to have_attributes(value: "blue", sticky: true, purchasable: false)
        expect(customisation.image.filename.to_s).to eq("computer-science.jpg")
      end
    end
  end
end
