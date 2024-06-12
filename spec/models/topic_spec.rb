# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Topic do
  it { is_expected.to belong_to(:subject) }

  it 'has a valid factory' do
    expect(build(:topic)).to be_valid
  end

  describe 'validations' do
    subject { build(:topic) }

    it { is_expected.to validate_presence_of(:name) }
  end
end
