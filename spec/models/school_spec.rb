# frozen_string_literal: true

require "rails_helper"

RSpec.describe School do
  it "has a valid factory" do
    expect(build(:school)).to be_valid
  end

  describe "validations" do
    subject { build(:school) }

    it { is_expected.to validate_presence_of(:client_id) }
    it { is_expected.to validate_uniqueness_of(:client_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:token) }
  end

  describe "#sync_status_label" do
    it "words a finished sync as synced" do
      expect(build_stubbed(:school, sync_status: :successful).sync_status_label).to eq("Synced")
    end

    it "words a stalled sync as timed out" do
      school = build_stubbed(:school, sync_status: :syncing, updated_at: (School::SYNC_TIMEOUT + 1.minute).ago)
      expect(school.sync_status_label).to eq("Sync timed out")
    end

    it "words a status outside the enum as unknown" do
      expect(build_stubbed(:school, sync_status: nil).sync_status_label).to eq("Unknown")
    end
  end

  describe "#sync_stalled?" do
    it "is stalled once a sync has run past the timeout" do
      expect(build_stubbed(:school, sync_status: :syncing, updated_at: (School::SYNC_TIMEOUT + 1.minute).ago)).to be_sync_stalled
    end

    it "is not stalled while a sync is within the timeout" do
      expect(build_stubbed(:school, sync_status: :syncing, updated_at: 1.minute.ago)).not_to be_sync_stalled
    end

    it "is not stalled when no sync is running, however old" do
      expect(build_stubbed(:school, sync_status: :successful, updated_at: 1.day.ago)).not_to be_sync_stalled
    end
  end

  describe "#start_sync" do
    let(:school) { create(:school) }

    it "sets sync_status to syncing" do
      school.start_sync
      expect(school.reload).to be_syncing
    end

    context "with mixed user roles" do
      let!(:student) { create(:student, school: school) }
      let!(:employee) { create(:teacher, school: school) }
      let!(:school_admin) { create(:school_admin, school: school) }
      before { school.start_sync }

      it "leaves every user enabled until the roster is known" do
        expect(User.where(school: school, disabled: true)).to be_empty
      end
    end

    context "with classrooms and enrollments" do
      let!(:classroom) { create(:classroom, school: school) }
      let!(:student) { create(:student, school: school) }
      let!(:enrollment) { create(:enrollment, classroom: classroom, user: student) }
      before { school.start_sync }

      it "disables all classrooms" do
        expect(classroom.reload).to be_disabled
      end

      it "destroys all enrollments" do
        expect(Enrollment.where(classroom: classroom)).to be_empty
      end

      it "resets the classroom enrollment count" do
        expect(classroom.reload.enrollments_count).to be_zero
      end
    end

    context "with another school also holding enrollments" do
      let(:other_school) { create(:school) }
      let!(:other_classroom) { create(:classroom, school: other_school) }
      let!(:other_enrollment) { create(:enrollment, classroom: other_classroom) }

      before { school.start_sync }

      it "leaves the other school enrolled" do
        expect(Enrollment.where(classroom: other_classroom)).to contain_exactly(other_enrollment)
      end

      it "leaves the other school enrollment count intact" do
        expect(other_classroom.reload.enrollments_count).to eq(1)
      end
    end
  end

  describe "#finish_sync" do
    let(:school) { create(:school, sync_status: :syncing) }

    it "sets sync_status to successful" do
      school.finish_sync([])
      expect(school.reload).to be_successful
    end

    it "records today as the last sync" do
      expect { school.finish_sync([]) }.to change { school.reload.last_sync }.from(nil).to(Date.current)
    end

    context "with students on and off the roster" do
      let!(:listed_student) { create(:student, school: school) }
      let!(:unlisted_student) { create(:student, school: school) }
      before { school.finish_sync([listed_student.id]) }

      it "disables the student the roster no longer lists" do
        expect(unlisted_student.reload).to be_disabled
      end

      it "keeps the listed student enabled" do
        expect(listed_student.reload).not_to be_disabled
      end
    end

    context "with enrolled and unenrolled employees on the roster" do
      let!(:classroom) { create(:classroom, school: school) }
      let!(:enrolled_employee) { create(:teacher, school: school) }
      let!(:unenrolled_employee) { create(:teacher, school: school) }
      let!(:enrollment) { create(:enrollment, classroom: classroom, user: enrolled_employee) }
      before { school.finish_sync([enrolled_employee.id, unenrolled_employee.id]) }

      it "disables unenrolled employees but not enrolled ones" do
        expect(unenrolled_employee.reload).to be_disabled
        expect(enrolled_employee.reload).not_to be_disabled
      end
    end

    context "with live leaderboard streams open" do
      let!(:listed_student) { create(:student, school: school) }
      let!(:unlisted_student) { create(:student, school: school) }

      it "disconnects the users it disables" do
        expect { school.finish_sync([listed_student.id]) }
          .to have_broadcasted_to("action_cable/#{unlisted_student.to_gid_param}")
          .with(type: "disconnect", reconnect: false)
      end

      it "leaves listed users connected" do
        expect { school.finish_sync([listed_student.id]) }
          .not_to have_broadcasted_to("action_cable/#{listed_student.to_gid_param}")
      end
    end

    context "with a school admin enrolled nowhere and off the roster" do
      let!(:school_admin) { create(:school_admin, school: school) }
      before { school.finish_sync([]) }

      it "keeps the school admin enabled" do
        expect(school_admin.reload).not_to be_disabled
      end
    end

    context "with question and lesson authors enrolled nowhere and off the roster" do
      let!(:question_author) { create(:question_author, school: school, subject: create(:subject)) }
      let!(:lesson_author) { create(:lesson_author, school: school, subject: create(:subject)) }
      before { school.finish_sync([]) }

      it "keeps the authors enabled" do
        expect([question_author, lesson_author].map(&:reload)).to all(have_attributes(disabled: false))
      end
    end

    context "with users from another school" do
      let!(:other_student) { create(:student) }
      before { school.finish_sync([]) }

      it "does not affect other schools' users" do
        expect(other_student.reload).not_to be_disabled
      end
    end
  end

  describe "#from_wonde" do
    let(:school) { described_class.from_wonde(OpenStruct.new(id: "1234", name: "test"), "token") }

    it "persists the school" do
      expect(school).to be_persisted
    end

    context "when a matching school already exists" do
      before { create(:school, client_id: "1234", name: "old name") }

      it "updates the existing school attributes" do
        expect(school).to have_attributes(client_id: "1234", name: "test")
      end
    end
  end
end
