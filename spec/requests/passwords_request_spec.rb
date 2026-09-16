# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Passwords", :default_creates do
  describe "requesting a reset" do
    let(:paranoid_notice) { "If your email address exists in our database" }

    context "with an admin's email" do
      let(:params) { {admin: {email: super_admin.email}} }

      it "sends the reset instructions" do
        expect { post admin_password_path, params: params }
          .to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it "redirects with a notice that doesn't confirm the account" do
        post admin_password_path, params: params
        expect(response).to redirect_to(new_admin_session_path)
        follow_redirect!
        expect(response.body).to include(paranoid_notice)
      end
    end

    context "with an unknown email" do
      let(:params) { {admin: {email: "nobody@example.com"}} }

      it "sends nothing" do
        expect { post admin_password_path, params: params }
          .not_to change(ActionMailer::Base.deliveries, :count)
      end

      it "redirects with the same notice as a known email" do
        post admin_password_path, params: params
        expect(response).to redirect_to(new_admin_session_path)
        follow_redirect!
        expect(response.body).to include(paranoid_notice)
      end
    end
  end
end
