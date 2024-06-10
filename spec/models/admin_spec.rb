# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin do
  it 'has a valid factory' do
    expect(build(:admin)).to be_valid
  end

  describe 'validations' do
    subject { build(:admin) }

    it { is_expected.to validate_presence_of(:role) }
  end
end
