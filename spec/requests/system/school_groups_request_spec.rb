# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::SchoolGroups", :default_creates, type: :request do
  before { sign_in super_admin }

  describe "GET /system/school_groups" do
    it "renders the index" do
      create(:school_group, name: "North")
      get system_school_groups_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("North")
    end
  end

  describe "GET /system/school_groups/:id/edit" do
    it "renders the edit form" do
      school_group = create(:school_group, name: "South")
      get edit_system_school_group_path(school_group)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("South")
    end
  end

  describe "POST /system/school_groups" do
    it "creates a school group" do
      expect {
        post system_school_groups_path, params: {school_group: {name: "East"}}
      }.to change(SchoolGroup, :count).by(1)
      expect(response).to redirect_to(system_school_groups_path)
    end

    it "does not create a school group with a blank name" do
      expect {
        post system_school_groups_path, params: {school_group: {name: ""}}
      }.not_to change(SchoolGroup, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /system/school_groups/:id" do
    it "does not save a blank name" do
      school_group = create(:school_group, name: "West")
      patch system_school_group_path(school_group), params: {school_group: {name: ""}}
      expect(response).to have_http_status(:unprocessable_content)
      expect(school_group.reload.name).to eq("West")
    end
  end
end
