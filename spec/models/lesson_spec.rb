# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson do
  it { is_expected.to have_many(:questions) }

  describe 'validations' do
    it { is_expected.to validate_length_of(:title).is_at_least(3) }
  end
end
