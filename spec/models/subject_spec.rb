# frozen_string_literal: true

require "rails_helper"

RSpec.describe Subject do
  it "has a valid factory" do
    expect(build(:subject)).to be_valid
  end

  describe "validations" do
    subject { build(:subject) }

    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe ".authored_by" do
    let(:author) { create(:user, role: "employee") }
    let!(:authored) { create(:subject) }
    let!(:other) { create(:subject) }

    before { author.add_role(:question_author, authored) }

    it "returns the subjects on which the user holds the role" do
      expect(described_class.authored_by(author, :question_author)).to contain_exactly(authored)
    end

    it "distinguishes roles" do
      expect(described_class.authored_by(author, :lesson_author)).to be_empty
    end

    it "ignores a role held on the class rather than a subject" do
      author.add_role(:question_author, Subject)
      expect(described_class.authored_by(author, :question_author)).to contain_exactly(authored)
    end
  end
end
