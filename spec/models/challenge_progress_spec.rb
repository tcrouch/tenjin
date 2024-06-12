# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChallengeProgress do
  it 'has a valid factory' do
    expect(build(:challenge_progress)).to be_valid
  end

  describe 'validations' do
    subject { build(:challenge_progress) }

    it { is_expected.to validate_uniqueness_of(:user).scoped_to(:challenge_id) }
  end
end
