# frozen_string_literal: true

require "rails_helper"

RSpec.describe FlaggedQuestion do
  it "has a valid factory" do
    expect(build(:flagged_question)).to be_valid
  end
end
