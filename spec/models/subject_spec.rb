# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subject do
  it 'has a valid factory' do
    expect(build(:subject)).to be_valid
  end

  describe 'validations' do
    subject { build(:subject) }

    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:name) }
  end
end
