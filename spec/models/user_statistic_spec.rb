# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserStatistic do
  it 'has a valid factory' do
    expect(build(:user_statistic)).to be_valid
  end
end
