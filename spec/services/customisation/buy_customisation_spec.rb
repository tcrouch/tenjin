# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customisation::BuyCustomisation, :default_creates do
  let(:student) { create(:student, school: school, challenge_points: 10) }
  let(:customisation) { create(:dashboard_customisation, cost: 5) }
  let(:old_customisation) { create(:dashboard_customisation, cost: 2) }

  before do
    create(:customisation_unlock, customisation: old_customisation, user: student)
  end

  context "when buying a new dashboard style" do
    it "creates a customisation unlock" do
      described_class.call(student, customisation)
      expect(CustomisationUnlock.where(customisation: customisation).count).to eq(1)
    end

    it "sets the new customisation as active" do
      described_class.call(student, customisation)
      expect(ActiveCustomisation.where(customisation: customisation).count).to eq(1)
    end

    it "deactivates the old customisation" do
      described_class.call(student, customisation)
      expect(ActiveCustomisation.where(customisation: old_customisation).count).to eq(0)
    end

    it "deducts the correct number of challenge points" do
      described_class.call(student, customisation)
      expect(student.reload.challenge_points).to eq(5)
    end
  end

  context "when buying a leaderboard icon" do
    let(:customisation) { create(:customisation, cost: 5, customisation_type: "leaderboard_icon") }

    it "sets the new icon as active" do
      described_class.call(student, customisation)
      expect(ActiveCustomisation.where(customisation: customisation).count).to eq(1)
    end

    it "deactivates the old icon" do
      described_class.call(student, customisation)
      expect(ActiveCustomisation.where(customisation: old_customisation).count).to eq(0)
    end

    it "creates a customisation unlock" do
      described_class.call(student, customisation)
      expect(CustomisationUnlock.where(customisation: customisation).count).to eq(1)
    end
  end

  context "when the student has no existing customisation" do
    before do
      CustomisationUnlock.destroy_all
    end

    it "creates a customisation unlock" do
      described_class.call(student, customisation)
      expect(CustomisationUnlock.where(customisation: customisation).count).to eq(1)
    end
  end

  context "when the student does not have enough points" do
    let(:student) { create(:student, school: school, challenge_points: 3) }

    it "returns an insufficient points error" do
      expect(described_class.call(student, customisation).errors).to eq("You do not have enough points")
    end
  end

  context "when buying a previously purchased customisation" do
    before do
      create(:customisation_unlock, customisation: customisation, user: student)
    end

    it "does not deduct any points" do
      described_class.call(student, customisation)
      expect { student.reload }.not_to change(student, :challenge_points)
    end

    it "sets the customisation as active" do
      described_class.call(student, customisation)
      expect(ActiveCustomisation.where(customisation: customisation).count).to eq(1)
    end

    it "deactivates the previously active customisation" do
      described_class.call(student, customisation)
      expect(ActiveCustomisation.where(customisation: old_customisation).count).to eq(0)
    end
  end
end
