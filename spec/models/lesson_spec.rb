# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson do
  it { is_expected.to have_many(:questions) }
end
