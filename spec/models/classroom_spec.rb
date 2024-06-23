# frozen_string_literal: true

require "rails_helper"

RSpec.describe Classroom do
  it "has a valid factory" do
    expect(build(:classroom)).to be_valid
  end

  describe "validations" do
    subject { build(:classroom) }

    it { is_expected.to validate_presence_of(:client_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:client_id) }
  end
end
