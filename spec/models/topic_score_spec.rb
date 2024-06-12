# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TopicScore do
  it { is_expected.to belong_to(:topic) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_one(:subject).through(:topic) }

  it 'has a valid factory' do
    expect(build(:topic_score)).to be_valid
  end

  describe 'validations' do
    subject { build(:topic_score) }

    it { is_expected.to allow_value(0).for(:score) }
    it { is_expected.not_to allow_value(-1).for(:score) }
  end
end
