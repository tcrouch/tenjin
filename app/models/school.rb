# frozen_string_literal: true

class School < ApplicationRecord
  has_many :users
  belongs_to :school_group, optional: true
  validates :client_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :token, presence: true

  enum sync_status: {never: 0, queued: 1, syncing: 2, successful: 3, failed: 4, needed: 5}

  def self.from_wonde(client_school, token)
    school = where(client_id: client_school.id).first_or_initialize
    school.name = client_school.name
    school.token = token
    school.sync_status = "never"
    school.save
    school
  end

  def self.from_wonde_sync_start(school)
    school.sync_status = "syncing"
    school.save

    User.where(school: school)
      .where.not(id: User.with_role(:school_admin))
      .update_all(disabled: true)
    Enrollment.joins(:classroom)
      .where("school_id = ?", school.id)
      .destroy_all
    Classroom.where("school_id = ?", school.id)
      .update_all(disabled: true)
  end

  def self.from_wonde_sync_end(school)
    User.where(school: school, role: "employee").find_each do |e|
      e.update_attribute("disabled", true) unless e.enrollments.exists?
    end

    school.sync_status = "successful"
    school.save
  end
end
