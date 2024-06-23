# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionStatistic do
  it "has a valid factory" do
    expect(build(:question_statistic)).to be_valid
  end
end
