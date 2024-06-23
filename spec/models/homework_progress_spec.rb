# frozen_string_literal: true

require "rails_helper"

RSpec.describe HomeworkProgress do
  it "has a valid factory" do
    expect(build(:homework_progress)).to be_valid
  end
end
