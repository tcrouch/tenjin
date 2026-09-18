# frozen_string_literal: true

class School::SyncSchool < ApplicationService
  def initialize(school)
    @school = school
  end

  def call
    # A second job queued behind a running sync must not start over it
    return if @school.syncing? && !@school.sync_stalled?

    confirm_access
    @roster_user_ids = []
    @school.start_sync
    School::WondeClasses.new(@school).each { |wonde_class| sync_class(wonde_class) }
    @school.finish_sync(@roster_user_ids)
  rescue
    # Left as syncing, the guard above would turn Delayed Job's retries of the raise into no-ops;
    # the columns are written directly so a validation failure cannot displace the error raised
    @school.update_columns(sync_status: :failed)
    raise
  end

  protected

  # A token or school id Wonde refuses must fail here, before start_sync empties the roster,
  # or every retry of the job would empty it again
  def confirm_access
    Wonderment::Client.new(@school.token).get("schools/#{@school.client_id}")
  end

  def sync_class(wonde_class)
    classroom = Classroom.from_wonde(@school, wonde_class)

    # A class Wonde gives no subject is a registration group: nobody on it joins the roster,
    # so nobody is enrolled in it either, or finish_sync would lock out those it just placed
    return if wonde_class["subject"].blank?

    @roster_user_ids.concat(User.from_wonde(@school, wonde_class, classroom))

    return if classroom.subject.blank?

    Enrollment.from_wonde(wonde_class, classroom)
  end
end
