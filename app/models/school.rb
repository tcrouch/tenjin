# frozen_string_literal: true

# A school whose classrooms, users and enrollments are synced from its Wonde roster
class School < ApplicationRecord
  belongs_to :school_group, optional: true
  has_many :classrooms
  has_many :users

  validates :client_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :token, presence: true

  enum :sync_status, {never: 0, queued: 1, syncing: 2, successful: 3, failed: 4, needed: 5}

  def self.from_wonde(client_school, token)
    school = where(client_id: client_school.id).first_or_initialize
    school.name = client_school.name
    school.token = token
    school.sync_status = :never
    school.save!
    school
  end

  # Live leaderboard points fan out to the whole school group when there is one
  def leaderboard_scope
    school_group_id ? "school-group-#{school_group_id}" : "school-#{id}"
  end

  def start_sync
    update!(sync_status: :syncing)

    Enrollment.joins(:classroom)
      .where(classrooms: {school_id: id})
      .destroy_all
    Classroom.where(school: self)
      .update_all(disabled: true)
  end

  # Users are disabled only here, once the roster is known, so a running sync locks nobody out
  def finish_sync(roster_user_ids)
    dropped = dropped_users(roster_user_ids)
    dropped.update_all(disabled: true)
    # Devise ends their sessions on the next request, which an open leaderboard socket never makes
    dropped.select(:id).find_each do |user|
      ActionCable.server.remote_connections.where(current_user: user).disconnect(reconnect: false)
    end
    update!(sync_status: :successful)
  end

  private

  # Everyone the roster no longer lists, plus employees it enrols nowhere; school admins keep access regardless
  def dropped_users(roster_user_ids)
    unlisted = User.where.not(id: roster_user_ids)
    unenrolled_employees = User.where(role: :employee).where.not(id: enrolled_user_ids)
    User.where(school: self)
      .where.not(id: User.with_role(:school_admin))
      .and(unlisted.or(unenrolled_employees))
  end

  def enrolled_user_ids
    Enrollment.joins(:classroom).where(classrooms: {school_id: id}).select(:user_id)
  end
end
