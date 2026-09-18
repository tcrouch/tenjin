# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customisation do
  it "has a valid factory" do
    expect(build(:customisation)).to be_valid
  end

  describe "validation" do
    subject { build(:customisation, customisation_type: type) }

    let(:type) { "leaderboard_icon" }

    it { is_expected.to validate_presence_of(:cost) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:value) }

    context "with a dashboard_style" do
      let(:type) { "dashboard_style" }

      it { is_expected.to validate_presence_of(:image) }
    end

    context "with a leaderboard_icon" do
      let(:type) { "leaderboard_icon" }

      it { is_expected.not_to validate_presence_of(:image) }
    end

    context "with a subject_image" do
      let(:type) { "subject_image" }

      it { is_expected.not_to validate_presence_of(:image) }
    end
  end

  context "when retired" do
    let!(:customisation) { create(:customisation, retired: true, purchasable: true, customisation_type: "leaderboard_icon") }

    it "is not purchasable" do
      expect(customisation.reload).not_to be_purchasable
    end
  end

  context "when not retired" do
    let!(:customisation) { create(:customisation, retired: false, purchasable: true, customisation_type: "leaderboard_icon") }

    it "is purchasable" do
      expect(customisation.reload).to be_purchasable
    end
  end

  describe ".with_image" do
    let!(:customisation) { create(:dashboard_customisation) }
    let!(:loaded) { described_class.with_image.find(customisation.id) }

    it "preloads the image blob" do
      queries = 0
      counter = ->(*) { queries += 1 }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        loaded.image.blob
      end

      expect(queries).to be_zero
    end

    it "does not preload variant records" do
      expect(loaded.image.blob.association(:variant_records)).not_to be_loaded
    end
  end

  describe "#for_sale?" do
    it "is true when purchasable and not retired" do
      expect(build_stubbed(:customisation, purchasable: true, retired: false)).to be_for_sale
    end

    it "is false when not purchasable" do
      expect(build_stubbed(:customisation, purchasable: false, retired: false)).not_to be_for_sale
    end

    it "is false when retired but still flagged purchasable" do
      expect(build_stubbed(:customisation, purchasable: true, retired: true)).not_to be_for_sale
    end
  end
end
