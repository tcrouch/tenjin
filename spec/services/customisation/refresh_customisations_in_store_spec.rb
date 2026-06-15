# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customisation::RefreshCustomisationsInStore, :default_creates do
  it "returns a success result" do
    result = described_class.call
    expect(result).to be_success
  end

  context "with retired customisations" do
    let!(:retired) { create(:dashboard_customisation, cost: 5, retired: true) }

    before do
      described_class.call
    end

    it "does not make retired customisations purchasable" do
      expect(retired.reload.purchasable).to be false
    end
  end

  context "with more than six available customisations" do
    before do
      create_list(:dashboard_customisation, 10)
      described_class.call
    end

    it "activates up to six customisations randomly" do
      expect(Customisation.where(purchasable: true).count).to eq(6)
    end
  end

  context "with sticky customisations" do
    before do
      create_list(:dashboard_customisation, 12)
      create_list(:dashboard_customisation, 5, sticky: true)
      described_class.call
    end

    it "always picks sticky customisations" do
      expect(Customisation.where(purchasable: true, sticky: true).count).to eq(5)
    end
  end

  context "with both leaderboard icons and dashboard styles" do
    before do
      create_list(:customisation, 12, customisation_type: "leaderboard_icon")
      create_list(:dashboard_customisation, 12)
      described_class.call
    end

    it "activates leaderboard icons" do
      expect(Customisation.where(purchasable: true, customisation_type: "leaderboard_icon").count).to eq(6)
    end

    it "activates dashboard styles" do
      expect(Customisation.where(purchasable: true, customisation_type: "dashboard_style").count).to eq(6)
    end
  end

  context "when a database error occurs mid-run" do
    let!(:purchasable_customisation) { create(:dashboard_customisation, purchasable: true) }
    let(:instance) { described_class.new }
    let(:error_message) { "simulated database error" }

    before do
      allow(instance).to receive(:make_six_purchasable).with("dashboard_style").and_call_original
      allow(instance).to receive(:make_six_purchasable).with("leaderboard_icon")
        .and_raise(ActiveRecord::StatementInvalid, error_message)
    end

    it "returns a failure result" do
      result = instance.call
      expect(result).to be_failure
    end

    it "includes the error message in the failure" do
      result = instance.call
      expect(result.error).to eq(error_message)
    end

    it "rolls back disable_all_customisations" do
      instance.call
      expect(purchasable_customisation.reload.purchasable).to be true
    end

    it "rolls back make_six_purchasable for dashboard_style" do
      create_list(:dashboard_customisation, 8, purchasable: false)
      instance.call
      expect(Customisation.where(purchasable: true, customisation_type: "dashboard_style").count).to eq(1)
    end
  end
end
