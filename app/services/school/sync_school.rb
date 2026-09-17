# frozen_string_literal: true

require "wondeclient"

class School::SyncSchool < ApplicationService
  def initialize(school)
    @school = school
    @client = Wonde::Client.new(school.token)
    @school_api = @client.school(school.client_id)
  end

  def call
    # A second job queued behind a running sync must not start over it
    return if @school.syncing? && !@school.sync_stalled?

    @roster_user_ids = []
    @school.start_sync
    fetch_class_data
    @school.finish_sync(@roster_user_ids)
  end

  protected

  def fetch_class_data
    @school_api.classes.all(%w[students employees]).each do |data|
      @sync_data = data
      sync_all_data
    end
  end

  def sync_all_data
    classroom = Classroom.from_wonde(@school, @sync_data)

    @roster_user_ids.concat(User.from_wonde(@school, @sync_data, classroom))

    return if classroom.subject.blank?

    Enrollment.from_wonde(@sync_data)
  end
end
