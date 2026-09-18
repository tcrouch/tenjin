# frozen_string_literal: true

require "rails_helper"

RSpec.describe School::AddSchool, :vcr do
  let(:school_token) { "faketoken0000000000000000000000000000000" }
  let(:school_id) { "A852030759" }
  let(:school_params) { ActionController::Parameters.new(token: school_token, client_id: school_id) }

  def sync_school
    described_class.call(school_params)
  end

  context "when no matching school exists" do
    before { sync_school }

    it "creates the school from the Wonde data" do
      expect(School.find_by(client_id: school_id).name).to eq "Outwood Grange Academy 1532082212"
    end
  end

  context "when a school with the same client_id exists" do
    before do
      create(:school, name: "Not outwood", client_id: "A852030759")
      sync_school
    end

    it "updates the school name in place without creating a duplicate" do
      expect(School.count).to eq(1)
      expect(School.find_by(client_id: school_id).name).to eq "Outwood Grange Academy 1532082212"
    end
  end
end

RSpec.describe School::AddSchool do
  # The id is typed by an admin, so whatever it holds must travel as one path segment
  context "when the id carries a character with meaning in a URL" do
    let(:school_params) { ActionController::Parameters.new(token: "a-token", client_id: "A852030759#x") }

    before do
      stub_request(:get, "https://api.wonde.com/v1.0/schools/A852030759%23x")
        .to_return(body: {"data" => {"id" => "A852030759#x", "name" => "Mistyped School"}}.to_json)
      described_class.call(school_params)
    end

    it "requests the school by the id as typed" do
      expect(a_request(:get, "https://api.wonde.com/v1.0/schools/A852030759%23x")).to have_been_made
    end
  end
end
