# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsageStatistic do
  it 'has a valid factory' do
    expect(build(:usage_statistic)).to be_valid
  end
end
