# frozen_string_literal: true

RSpec.shared_context "with wonde_test_data", shared_context: :metadata do
  let(:school_token) { "2a550dc912f6a63488af42352b79c5961e87daf9" }
  let(:school_id) { "A852030759" }
  let(:school_name) { "Outwood Grange Academy 1532082212" }
  let(:school_params) { ActionController::Parameters.new(token: school_token, client_id: school_id) }
  let(:school) do
    create(:school, client_id: school_id, name: school_name,
      token: school_token, sync_status: "successful", permitted: true)
  end

  let(:classroom_client_id) { "A1906124304" }
  let(:classroom_name) { "SOC 2" }

  let(:student_upi) { "1479cf1d289684f08600c9ad1f6406fc" }
  let(:student_forename) { "Leo" }
  let(:student_wonde) { create(:user, forename: "Leo", surname: "Ward", upi: student_upi, school: school) }

  let(:employee_upi) { "caea4baa5b7adac73ab1259987d2bcc0" }
  let(:employee_name) { "Emma" }
end
