# frozen_string_literal: true

require "rails_helper"

RSpec.describe Homework do
  let(:classroom) { create(:classroom_with_students, student_count: 2) }

  it "has a valid factory" do
    expect(build(:homework)).to be_valid
  end

  describe "validation" do
    subject { build(:homework, classroom: classroom, due_date: due_on) }

    let(:due_on) { 1.week.from_now }

    it { is_expected.to validate_presence_of(:due_date) }
    it { is_expected.to validate_presence_of(:topic) }
    it { is_expected.to validate_presence_of(:required) }

    context "when due_date is in the past" do
      let(:due_on) { 1.day.ago }

      it { is_expected.not_to be_valid }
    end
  end

  describe "#save" do
    let(:homework) { build(:homework, classroom: classroom) }
    let(:teacher) { create(:teacher) }

    it "increases user progresses after being created" do
      expect { homework.save }.to change(HomeworkProgress, :count).by 2
    end

    context "with a teacher enrolled in the class" do
      it "does not create an additional progress for them" do
        create(:enrollment, classroom: classroom, user: teacher)
        expect { homework.save }.to change(HomeworkProgress, :count).by 2
      end
    end
  end

  describe "#destroy" do
    let!(:homework) { create(:homework, classroom: classroom) }

    it "deletes user progresses after being destroyed" do
      expect { homework.destroy }.to change(HomeworkProgress, :count).by(-2)
    end
  end
end
