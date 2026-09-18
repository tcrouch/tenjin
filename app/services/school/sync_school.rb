# frozen_string_literal: true

class School::SyncSchool < ApplicationService
  def initialize(school)
    @school = school
  end

  def call
    # A second job queued behind a running sync must not start over it
    return if @school.syncing? && !@school.sync_stalled?

    @roster_user_ids = []
    @started = false
    School::WondeClasses.new(@school).each do |wonde_class|
      start_sync_once
      sync_class(wonde_class)
    end
    start_sync_once
    @school.finish_sync(@roster_user_ids)
  rescue
    # Left as syncing, the guard above would turn Delayed Job's retries of the raise into no-ops;
    # the columns are written directly so a validation failure cannot displace the error raised
    @school.update_columns(sync_status: :failed)
    raise
  end

  protected

  # The first class arrives only once Wonde has answered the first page, so a listing it refuses
  # fails before start_sync empties the roster, and every retry of the job leaves it alone too
  def start_sync_once
    return if @started

    @school.start_sync
    @started = true
  end

  def sync_class(wonde_class)
    classroom = Classroom.from_wonde(@school, wonde_class)

    # A class Wonde gives no subject is a registration group: nobody on it joins the roster,
    # so nobody is enrolled in it either, or finish_sync would lock out those it just placed
    return if wonde_class["subject"].blank?

    user_ids = User.from_wonde(@school, wonde_class, classroom)
    @roster_user_ids.concat(user_ids)

    return if classroom.subject.blank?

    Enrollment.enroll(classroom, user_ids)
  end
end
