# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminAreaHelper do
  describe "#admin_avatar_class" do
    let(:palette) { (0...described_class::AVATAR_COLOURS).map { |index| "admin-avatar-#{index}" } }

    it "names a colour the stylesheet defines" do
      classes = (1..(described_class::AVATAR_COLOURS * 3)).map do |id|
        helper.admin_avatar_class(build_stubbed(:admin, id: id))
      end

      expect(classes).to all(be_in(palette))
    end

    it "gives consecutive admins different colours" do
      first = helper.admin_avatar_class(build_stubbed(:admin, id: 8))
      second = helper.admin_avatar_class(build_stubbed(:admin, id: 9))

      expect(first).not_to eq(second)
    end
  end
end
