# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolGroup do
  it 'has a valid factory' do
    expect(build(:school_group)).to be_valid
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end
end
