# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customisation::RefreshCustomisationsInStore, :default_creates do
  it "does not make retired customisations purchasable" do
    retired = create(:dashboard_customisation, cost: 5, retired: true)
    described_class.call
    expect(retired.reload.purchasable).to be(false)
  end

  it "activates up to six customisations randomly" do
    create_list(:dashboard_customisation, 10)
    described_class.call
    expect(Customisation.where(purchasable: true).count).to eq(6)
  end

  it "always picks sticky customisations" do
    create_list(:dashboard_customisation, 12)
    create_list(:dashboard_customisation, 5, sticky: true)
    described_class.call
    expect(Customisation.where(purchasable: true, sticky: true).count).to eq(5)
  end

  it "activates both leaderboard icons and dashboard styles" do
    create_list(:customisation, 12, customisation_type: "leaderboard_icon")
    create_list(:dashboard_customisation, 12)
    described_class.call
    expect(Customisation.where(purchasable: true, customisation_type: "leaderboard_icon").count).to eq(6)
  end
end
