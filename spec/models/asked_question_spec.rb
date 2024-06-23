# frozen_string_literal: true

require "rails_helper"

RSpec.describe AskedQuestion do
  it "has a valid factory" do
    expect(build(:asked_question)).to be_valid
  end
end
