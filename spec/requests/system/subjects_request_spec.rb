# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::Subjects", :default_creates, type: :request do
  before { sign_in super_admin }

  describe "GET /system/subjects" do
    it "renders the index" do
      create(:subject, name: "Maths")
      get system_subjects_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Maths")
    end
  end

  describe "GET /system/subjects/:id/edit" do
    it "renders the edit form" do
      subject_record = create(:subject, name: "Chemistry")
      get edit_system_subject_path(subject_record)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Chemistry")
    end
  end

  describe "POST /system/subjects" do
    it "creates a subject" do
      expect {
        post system_subjects_path, params: {subject: {name: "Biology"}}
      }.to change(Subject, :count).by(1)
    end
  end

  describe "PATCH /system/subjects/:id" do
    it "updates a subject" do
      subject_record = create(:subject, name: "Physics")
      patch system_subject_path(subject_record), params: {subject: {name: "Astronomy"}}
      expect(subject_record.reload.name).to eq("Astronomy")
    end

    it "does not save an invalid name" do
      subject_record = create(:subject, name: "Geography")
      patch system_subject_path(subject_record), params: {subject: {name: ""}}
      expect(response).to have_http_status(:unprocessable_content)
      expect(subject_record.reload.name).to eq("Geography")
    end
  end

  describe "DELETE /system/subjects/:id" do
    it "deactivates the subject" do
      subject_record = create(:subject)
      delete system_subject_path(subject_record)
      expect(subject_record.reload.active).to be(false)
    end
  end
end
