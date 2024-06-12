# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActiveCustomisation do
  it 'has a valid factory' do
    expect(build(:active_customisation)).to be_valid
  end
end
