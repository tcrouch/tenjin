# frozen_string_literal: true

require "rails_helper"

RSpec.describe SchoolsHelper do
  describe "#sync_status_badge" do
    def badge_for(school)
      Capybara.string(helper.sync_status_badge(school))
    end

    {
      "never" => "Never synced",
      "queued" => "Queued",
      "syncing" => "Syncing",
      "successful" => "Synced",
      "failed" => "Failed",
      "needed" => "Sync needed"
    }.each do |status, label|
      it "names the #{status} status in words" do
        expect(badge_for(build_stubbed(:school, sync_status: status))).to have_css(".badge", exact_text: label)
      end
    end

    it "spins the icon while syncing" do
      expect(badge_for(build_stubbed(:school, sync_status: "syncing"))).to have_css(".badge i.fa-spin[aria-hidden='true']")
    end

    it "falls back to an unknown badge for a status outside the enum" do
      expect(badge_for(build_stubbed(:school, sync_status: nil))).to have_css(".badge", exact_text: "Unknown")
    end

    context "when a sync has run past its timeout" do
      let(:school) { build_stubbed(:school, sync_status: "syncing", updated_at: (School::SYNC_TIMEOUT + 1.minute).ago) }

      it "warns that it timed out instead of spinning" do
        expect(badge_for(school)).to have_css(".badge.text-bg-warning", exact_text: "Sync timed out")
          .and have_no_css(".fa-spin")
      end
    end

    context "with a recorded last sync" do
      let(:school) { build_stubbed(:school, last_sync: Date.new(2026, 9, 3)) }

      it "dates it" do
        expect(badge_for(school)).to have_css("small", exact_text: "Last synced 3 Sep 2026")
      end
    end

    context "with no recorded sync" do
      let(:school) { build_stubbed(:school, last_sync: nil) }

      it "shows no date" do
        expect(badge_for(school)).to have_no_css("small")
      end
    end

    context "when a re-added school is back to never with its old date" do
      let(:school) { build_stubbed(:school, sync_status: "never", last_sync: Date.new(2026, 9, 3)) }

      it "shows no date" do
        expect(badge_for(school)).to have_no_css("small")
      end
    end
  end
end
