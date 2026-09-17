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

      it "shows no breadcrumb on a top-level page" do
        expect(Capybara.string(response.body)).to have_no_css("nav[aria-label='Breadcrumb']")
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
      expect(stream_update("permitted_school_#{school.id}")).to have_field("Permitted", type: "checkbox", checked: false)
    end
  end

  describe "GET /system/schools/stats" do
    before { sign_in super_admin }

    it "renders overall_statistics for super admins" do
      get stats_system_schools_path
      expect(response).to have_http_status(:ok)
    end

    context "with a customisation bought twice and one never bought" do
      let!(:bought) { create(:customisation) }
      let!(:unbought) { create(:customisation) }
      let!(:unlocks) { create_list(:customisation_unlock, 2, customisation: bought) }

      before { get stats_system_schools_path }

      it "counts the purchases of each" do
        page = Capybara.string(response.body)
        expect(page).to have_css("#customisation_#{bought.id} td:last-child", exact_text: "2")
          .and have_css("#customisation_#{unbought.id} td:last-child", exact_text: "0")
      end
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

      context "with pupils and staff on the roll" do
        let!(:pupils) { create_list(:student, 2, school: school) }
        let!(:staff) { create(:teacher, school: school) }

        # The outer GET ran before these records existed
        before { get system_school_path(school) }

        it "counts each role" do
          expect(Capybara.string(response.body)).to have_xpath("//tr[td='Students'][td='2']")
            .and have_xpath("//tr[td='Employees'][td='1']")
        end
      end

      it "titles the tab after the school and leads back to Schools" do
        expect(Capybara.string(response.body)).to have_title("#{school.name} · Tenjin admin")
          .and have_css("nav[aria-label='Breadcrumb'] a[href='#{system_schools_path}']", exact_text: "Schools")
          .and have_css(".breadcrumb-item.active[aria-current='page']", exact_text: school.name)
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
      expect(stream_update("sync_status_school_#{school.id}")).to have_css(".badge", exact_text: "Queued")
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
