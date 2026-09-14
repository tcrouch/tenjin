# frozen_string_literal: true

require "rails_helper"

RSpec.describe Topic do
  it { is_expected.to belong_to(:subject) }

  it "has a valid factory" do
    expect(build(:topic)).to be_valid
  end

  describe "validations" do
    subject { build(:topic) }

    it { is_expected.to validate_presence_of(:name) }
  end

  describe "#destroy" do
    it "succeeds when the default lesson is one of its own lessons" do
      topic = create(:topic)
      lesson = create(:lesson, topic: topic)
      topic.update!(default_lesson: lesson)

      expect { topic.destroy! }.to change(Lesson, :count).by(-1)
    end
  end
end
