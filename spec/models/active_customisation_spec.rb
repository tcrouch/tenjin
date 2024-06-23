# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveCustomisation do
  it "has a valid factory" do
    expect(build(:active_customisation)).to be_valid
  end

  describe "validations" do
    subject { build(:active_customisation) }

    it { is_expected.to validate_uniqueness_of(:user).scoped_to(:customisation_id) }
  end
end
