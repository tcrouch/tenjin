# frozen_string_literal: true

require "rails_helper"
require "support/api_data"

RSpec.describe Enrollment do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:classroom) }

  it "has a valid factory" do
    expect(build(:enrollment)).to be_valid
  end

  describe "validation" do
    subject { build(:enrollment) }

    it { is_expected.to validate_uniqueness_of(:user).scoped_to(:classroom_id) }
  end

  context "when a user is enrolled in one classroom" do
    let(:school) { create(:school, client_id: "1234") }
    let(:classrooms) { create_list(:classroom, 2, school: school) }
    let(:student) { create(:student, school: school) }

    before do
      create(:enrollment, classroom: classrooms[0], user: student)
    end

    it "allows enrollment in multiple classrooms" do
      expect { create(:enrollment, classroom: classrooms[1], user: student) }.not_to raise_error
    end

    it "raises an error on duplicate enrollment" do
      expect { create(:enrollment, classroom: classrooms[0], user: student) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe ".from_wonde" do
    let(:classroom) { create(:classroom) }
    let!(:pupil) { create(:student, school: classroom.school, upi: "upi-pupil") }
    let!(:teacher) { create(:teacher, school: classroom.school, upi: "upi-teacher") }

    def wonde_class(students: [], employees: [])
      {"id" => classroom.client_id,
       "students" => {"data" => students.map { |upi| {"upi" => upi} }},
       "employees" => {"data" => employees.map { |upi| {"upi" => upi} }}}
    end

    context "with a pupil and a teacher listed" do
      before { described_class.from_wonde(wonde_class(students: ["upi-pupil"], employees: ["upi-teacher"]), classroom) }

      it "enrolls both" do
        expect(classroom.reload.users).to contain_exactly(pupil, teacher)
      end

      # The rows go in without the counter_cache callback, so the count is written by hand
      it "counts the enrollments on the classroom" do
        expect(classroom.reload.enrollments_count).to eq(2)
      end

      it "enables the classroom" do
        expect(classroom.reload).not_to be_disabled
      end
    end

    context "with someone listed who has no account" do
      before { described_class.from_wonde(wonde_class(students: %w[upi-pupil upi-unknown]), classroom) }

      it "enrolls only those with accounts" do
        expect(classroom.reload.users).to contain_exactly(pupil)
      end
    end

    context "with nobody listed" do
      before { described_class.from_wonde(wonde_class, classroom) }

      it "creates no enrollments" do
        expect(classroom.reload.enrollments).to be_empty
      end

      it "disables the classroom" do
        expect(classroom.reload).to be_disabled
      end
    end

    # A sync runs this once per class over a roster start_sync has just emptied, so a class
    # costs one statement however many people it lists
    it "enrolls the whole class in one insert" do
      inserts = 0
      counter = ->(_name, _start, _finish, _id, payload) { inserts += 1 if payload[:sql].start_with?("INSERT") }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        described_class.from_wonde(wonde_class(students: ["upi-pupil"], employees: ["upi-teacher"]), classroom)
      end

      expect(inserts).to eq(1)
    end
  end
end
