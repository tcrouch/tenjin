# frozen_string_literal: true

require "rails_helper"

RSpec.describe School::SyncSchool, :vcr do
  include ActiveJob::TestHelper

  include_context "with api_data"
  include_context "with wonde_test_data"

  let(:sociology_class) { Classroom.find_by(client_id: classroom_client_id) }

  def sync_school_with_wonde
    school = School::AddSchool.call(school_params)
    perform_enqueued_jobs do
      SyncSchoolJob.perform_later school
    end
  end

  context "with classroom data" do
    before do
      sync_school_with_wonde
    end

    it "creates classrooms" do
      expect(Classroom.count).to be_positive
    end

    it "creates classrooms with the correct client id" do
      expect(Classroom.find_by(client_id: classroom_client_id)).to have_attributes(name: classroom_name)
    end

    it "creates classrooms for the correct school" do
      expect(sociology_class.school).to have_attributes(client_id: school_id)
    end

    context "when the classroom has a subject assigned" do
      before do
        sociology_class.update!(subject: create(:subject))
        sync_school_with_wonde
      end

      it "enrolls students into the classroom" do
        expect(sociology_class.reload.enrollments).not_to be_empty
      end

      context "when synced multiple times" do
        before do
          sync_school_with_wonde
        end

        it "does not duplicate enrollments" do
          expect(Enrollment.where(user: User.find_by!(upi: student_upi)).count).to eq(1)
        end
      end
    end

    context "when a classroom no longer exists in the MIS" do
      before do
        create(:classroom, school: School.find_by!(client_id: school_id), client_id: "1234")
        sync_school_with_wonde
      end

      it "disables classrooms that no longer exist in the MIS" do
        expect(Classroom.find_by(client_id: "1234")).to be_disabled
      end
    end
  end

  context "when receiving updated classroom data" do
    let(:existing_school) { create(:school, client_id: school_id) }
    let!(:existing_classroom) { create(:classroom, client_id: classroom_client_id, school: existing_school) }

    context "when synced with new data" do
      before { sync_school_with_wonde }

      it "updates the classroom name" do
        expect(Classroom.find_by!(client_id: classroom_client_id).name).to eq classroom_name
      end
    end

    context "when a student no longer exists in the MIS" do
      let!(:departed_student) { create(:student, school: existing_school) }

      before { sync_school_with_wonde }

      it "disables the student" do
        expect(departed_student.reload).to be_disabled
      end
    end

    context "when a student enrollment no longer exists in the MIS" do
      let(:student) { create(:student, upi: "1234") }

      before do
        create(:enrollment, classroom: existing_classroom, user: student)
        sync_school_with_wonde
      end

      it "removes enrollments that no longer exist in the MIS" do
        expect(Enrollment.where(user: student)).to be_empty
      end
    end
  end

  context "with student data" do
    before do
      sync_school_with_wonde
      sociology_class.update!(subject: create(:subject))
      sync_school_with_wonde
    end

    it "creates student entries" do
      expect(User.where(role: "student")).not_to be_empty
    end

    it "creates employee entries" do
      expect(User.where(role: "employee")).not_to be_empty
    end

    it "links each student to the correct school" do
      expect(User.find_by!(upi: student_upi).school.name).to eq(school_name)
    end

    it "leaves listed students enabled" do
      expect(User.find_by!(upi: student_upi)).not_to be_disabled
    end
  end

  context "when given updated student data" do
    context "when student details have changed in the MIS" do
      before do
        create(:student, forename: "test", upi: student_upi)
        sync_school_with_wonde
        sociology_class.update!(subject: create(:subject))
        sync_school_with_wonde
      end

      it "updates student details" do
        expect(User.find_by(upi: student_upi).forename).to eq(student_forename)
      end
    end

    context "when the student has existing challenge points" do
      let!(:student_with_points) { create(:student, upi: student_upi, challenge_points: 50) }

      before do
        sync_school_with_wonde
      end

      it "preserves the student's challenge points" do
        expect(User.find_by(upi: student_upi).challenge_points).to eq(50)
      end
    end
  end

  context "with a new teacher assigned to a classroom" do
    before do
      school = create(:school, client_id: school_id)
      classroom = create(:classroom, client_id: classroom_client_id, school: school)
      employee = create(:user, role: "employee")
      create(:enrollment, classroom: classroom, user: employee)
      sync_school_with_wonde
    end

    it "updates the classroom owner to the current employee" do
      expect(Classroom.find_by(client_id: classroom_client_id).users
        .find_by(role: "employee").upi).to eq(employee_upi)
    end
  end

  context "with updated employee data" do
    before do
      create(:teacher, upi: employee_upi)
      sync_school_with_wonde
      sociology_class.update!(subject: create(:subject))
      sync_school_with_wonde
    end

    it "updates employee details" do
      expect(User.find_by(upi: employee_upi).forename).to eq(employee_name)
    end
  end
end

RSpec.describe School::SyncSchool do
  context "when Wonde fails mid-sync" do
    let(:school) { create(:school, sync_status: :successful) }

    before { stub_request(:get, /wonde/).to_return(status: 503) }

    it "marks the school failed and lets the error through to the job" do
      expect { described_class.call(school) }.to raise_error(Wonderment::Error, "Wonde responded 503")
      expect(school.reload).to be_failed
    end
  end

  # Delayed Job retries the raise, so a roster wiped before the first request would be wiped again
  # on every attempt
  context "when Wonde refuses the school's token" do
    let(:school) { create(:school, sync_status: :successful) }
    let(:classroom) { create(:classroom, school: school, subject: create(:subject)) }
    let!(:enrollment) { create(:enrollment, classroom: classroom, user: create(:student, school: school)) }

    before do
      stub_request(:get, /wonde/).to_return(status: 401)
      described_class.call(school)
    rescue Wonderment::Error
      nil
    end

    it "leaves the enrollments in place" do
      expect(Enrollment.exists?(enrollment.id)).to be true
    end

    it "leaves the classrooms enabled" do
      expect(classroom.reload).not_to be_disabled
    end

    it "marks the school failed" do
      expect(school.reload).to be_failed
    end
  end

  # Wonde's classes include registration groups with no subject; nobody on one is put on the
  # roster, so enrolling them would hand out places the same sync then locks
  context "when an admin has mapped a class that Wonde gives no subject" do
    let(:school) { create(:school, client_id: "NOSUBJ", token: "a-token", sync_status: :successful) }
    let!(:classroom) { create(:classroom, school: school, client_id: "REG", subject: create(:subject)) }
    let!(:pupil) { create(:student, school: school, upi: "upi-reg") }

    before do
      stub_request(:get, "https://api.wonde.com/v1.0/schools/NOSUBJ/classes?cursor=true&include=students,employees&per_page=50")
        .to_return(body: wonde_page([wonde_class("REG", subject: nil, students: [wonde_person(upi: "upi-reg")])]))
      described_class.call(school)
    end

    it "enrolls nobody in it" do
      expect(classroom.reload.enrollments).to be_empty
    end

    it "keeps the pupil off the roster" do
      expect(pupil.reload).to be_disabled
    end
  end

  context "when a pupil is listed without a upi" do
    let(:school) { create(:school, client_id: "NOUPI", token: "a-token", sync_status: :successful) }
    let!(:classroom) { create(:classroom, school: school, client_id: "C1", subject: create(:subject)) }
    let!(:stray_user) { create(:student, :without_upi) }

    before do
      stub_request(:get, "https://api.wonde.com/v1.0/schools/NOUPI/classes?cursor=true&include=students,employees&per_page=50")
        .to_return(body: wonde_page([wonde_class("C1", students: [wonde_person(upi: nil), wonde_person(upi: "upi-ok")])]))
      described_class.call(school)
    end

    it "enrolls only the pupils with a upi" do
      expect(classroom.reload.users.pluck(:upi)).to contain_exactly("upi-ok")
    end
  end

  context "when Wonde refuses the classes listing but not the school" do
    let(:school) { create(:school, client_id: "SCOPED", token: "a-token", sync_status: :successful) }
    let(:classroom) { create(:classroom, school: school, subject: create(:subject)) }
    let!(:enrollment) { create(:enrollment, classroom: classroom, user: create(:student, school: school)) }

    before do
      stub_request(:get, "https://api.wonde.com/v1.0/schools/SCOPED/classes?cursor=true&include=students,employees&per_page=50")
        .to_return(status: 403)
      described_class.call(school)
    rescue Wonderment::Error
      nil
    end

    it "leaves the enrollments in place" do
      expect(Enrollment.exists?(enrollment.id)).to be true
    end

    it "leaves the classrooms enabled" do
      expect(classroom.reload).not_to be_disabled
    end
  end

  context "when Wonde lists no classes" do
    let(:school) { create(:school, client_id: "EMPTY", token: "a-token", sync_status: :successful) }
    let!(:classroom) { create(:classroom, school: school, subject: create(:subject)) }

    before do
      stub_request(:get, "https://api.wonde.com/v1.0/schools/EMPTY/classes?cursor=true&include=students,employees&per_page=50")
        .to_return(body: wonde_page([]))
      described_class.call(school)
    end

    it "disables every classroom" do
      expect(classroom.reload).to be_disabled
    end

    it "records the sync as successful" do
      expect(school.reload).to be_successful
    end
  end

  context "when the school record no longer passes validation" do
    let(:school) { create(:school, sync_status: :successful) }

    before do
      school.update_column(:name, "")
      stub_request(:get, /wonde/).to_return(status: 503)
    end

    it "lets the Wonde error through rather than the validation one" do
      expect { described_class.call(school) }.to raise_error(Wonderment::Error)
    end

    it "still marks the school failed" do
      begin
        described_class.call(school)
      rescue Wonderment::Error
        nil
      end
      expect(school.reload).to be_failed
    end
  end
end

RSpec.describe School::SyncSchool do
  describe "when the roster spans several pages" do
    let(:school) { create(:school, client_id: "PAGED", token: "a-token", sync_status: :successful) }
    let(:quiz_subject) { create(:subject) }
    let(:first_page_url) do
      "https://api.wonde.com/v1.0/schools/PAGED/classes?cursor=true&include=students,employees&per_page=50"
    end
    # Wonde hands back an absolute next URL that repeats the original include and per_page
    let(:second_page_url) do
      "https://api.wonde.com/v1.0/schools/PAGED/classes?per_page=50&include=students%2Cemployees&page=2"
    end

    let!(:first_page_classroom) { create(:classroom, school: school, client_id: "C1", subject: quiz_subject) }
    let!(:second_page_classroom) { create(:classroom, school: school, client_id: "C2", subject: quiz_subject) }
    let!(:second_page_pupil) { create(:student, school: school, upi: "upi-page-2") }

    before do
      stub_request(:get, first_page_url)
        .to_return(body: wonde_page([wonde_class("C1", students: [wonde_person(upi: "upi-page-1")])], second_page_url))
      stub_request(:get, second_page_url)
        .to_return(body: wonde_page([wonde_class("C2", students: [wonde_person(upi: "upi-page-2")])]))
      described_class.call(school)
    end

    it "enrolls pupils listed only on a later page" do
      expect(second_page_classroom.reload.users.pluck(:upi)).to contain_exactly("upi-page-2")
    end

    # A page the sync never reads leaves its pupils off the roster, and finish_sync locks them out
    it "leaves a pupil listed only on a later page enabled" do
      expect(second_page_pupil.reload).not_to be_disabled
    end

    it "keeps a classroom from every page enabled" do
      expect(Classroom.where(school: school, disabled: false).pluck(:client_id))
        .to contain_exactly("C1", "C2")
    end

    it "records the sync as successful" do
      expect(school.reload).to be_successful
    end
  end
end
