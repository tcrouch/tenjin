# frozen_string_literal: true

require "rails_helper"

RSpec.describe AllTimeTopicScore do
  it "has a valid factory" do
    expect(build(:all_time_topic_score)).to be_valid
  end

  describe "validations" do
    subject { build(:all_time_topic_score) }

    it { is_expected.to validate_numericality_of(:score).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_uniqueness_of(:user).scoped_to(:topic_id) }
  end
end
