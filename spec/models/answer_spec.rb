# frozen_string_literal: true

require "rails_helper"

RSpec.describe Answer do
  it "has a valid factory" do
    expect(build(:answer)).to be_valid
  end

  describe "validations" do
    subject { build(:answer) }

    it { is_expected.to validate_presence_of(:text) }
  end
end
