# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuizPolicy, :default_creates do
  subject(:policy) { described_class.new(student, Quiz.new(subject: quiz_subject)) }

  let!(:enrollment) { create(:enrollment, user: student, classroom: classroom) }

  it "allows an enrolled student to start a quiz" do
    expect(policy).to be_new.and be_create
  end

  context "when the student is not enrolled in the subject" do
    subject(:policy) { described_class.new(student, Quiz.new(subject: create(:subject))) }

    it "refuses" do
      expect(policy).not_to be_new
      expect(policy).not_to be_create
    end
  end

  context "when the school is not permitted" do
    let(:school) { create(:school, permitted: false) }

    it "refuses" do
      expect(policy).not_to be_new
      expect(policy).not_to be_create
    end
  end

  context "with no subject" do
    subject(:policy) { described_class.new(student, Quiz.new) }

    it "refuses" do
      expect(policy).not_to be_new
      expect(policy).not_to be_create
    end
  end
end
