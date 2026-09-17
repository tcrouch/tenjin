# frozen_string_literal: true

class School::SyncSchool < ApplicationService
  def initialize(school)
    @school = school
  end

  def call
    # A second job queued behind a running sync must not start over it
    return if @school.syncing? && !@school.sync_stalled?

    @roster_user_ids = []
    @school.start_sync
    School::WondeClasses.new(@school).each { |wonde_class| sync_class(wonde_class) }
    @school.finish_sync(@roster_user_ids)
  rescue
    # Left as syncing, the guard above would turn Delayed Job's retries of the raise into no-ops
    @school.update!(sync_status: :failed)
    raise
  end

  protected

  def sync_class(wonde_class)
    classroom = Classroom.from_wonde(@school, wonde_class)

    @roster_user_ids.concat(User.from_wonde(@school, wonde_class, classroom))

    return if classroom.subject.blank?

    Enrollment.from_wonde(wonde_class)
  end
end
