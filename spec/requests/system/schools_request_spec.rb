# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::Schools", :default_creates, type: :request do
  let(:school_group_admin) { create(:school_group_admin) }
  let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html, text/html"} }

  # Capybara.string drops a <template>'s content, so read the stream's markup directly
  def stream_update(target)
    template = Nokogiri::HTML4(response.body).at_css("turbo-stream[action='update'][target='#{target}'] template")
    Capybara.string(template&.inner_html.to_s)
  end

  describe "GET /system/schools" do
    let!(:school) { super() }

    before do
      sign_in admin
      get system_schools_path
    end

    context "as a super admin" do
      let(:admin) { super_admin }

      it "offers a sync" do
        expect(Capybara.string(response.body)).to have_button("Sync")
      end
    end

    context "as a school group admin" do
      let(:admin) { school_group_admin }

      it "offers no sync, which only super admins may run" do
        expect(Capybara.string(response.body)).to have_no_button("Sync")
      end
    end
  end

  describe "PATCH /system/schools/:id" do
    before { sign_in super_admin }

    it "redraws the permitted toggle in its new state" do
      patch system_school_path(school), params: {school: {permitted: false}}, headers: turbo_headers
      expect(stream_update("permitted_school_#{school.id}")).to have_css("button[aria-pressed='false']")
    end
  end

  describe "GET /system/schools/stats" do
    before { sign_in super_admin }

    it "renders overall_statistics for super admins" do
      get stats_system_schools_path
      expect(response).to have_http_status(:ok)
    end

    it "marks only Statistics as the current page, though its path is under Schools" do
      get stats_system_schools_path
      expect(Capybara.string(response.body)).to have_css("#navbar-main a.nav-link.active[aria-current='page']", count: 1)
        .and have_css("a.nav-link.active", exact_text: "Statistics")
    end
  end

  describe "GET /system/schools/:id" do
    before do
      sign_in admin
      get system_school_path(school)
    end

    context "as a super admin" do
      let(:admin) { super_admin }

      it "links to role management for the school" do
        expect(response.body).to include(manage_roles_system_users_path(school: school))
      end
    end

    context "as a school group admin" do
      let(:admin) { school_group_admin }

      it "does not link to role management" do
        expect(response.body).not_to include(manage_roles_system_users_path(school: school))
      end
    end
  end

  describe "PATCH /system/schools/:id/sync" do
    before { sign_in super_admin }

    it "queues a sync as admin" do
      expect { patch sync_system_school_path(school), headers: turbo_headers }
        .to change { school.reload.sync_status }.from("successful").to("queued")
        .and have_enqueued_job(SyncSchoolJob).with(school)
    end

    it "redraws the sync status as queued" do
      patch sync_system_school_path(school), headers: turbo_headers
      expect(stream_update("sync_status_school_#{school.id}")).to have_css("i.fa-clock")
    end
  end
end

RSpec.describe "Schools (user-side)", :default_creates, type: :request do
  describe "PATCH /schools/:id/sync" do
    it "queues a sync as school_admin User" do
      sign_in school_admin
      patch sync_school_path(school)
      expect(response).to have_http_status(:no_content)
      expect(school.reload.sync_status).to eq("queued")
    end
  end
end
