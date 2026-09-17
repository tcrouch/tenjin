# frozen_string_literal: true

class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :classroom, counter_cache: true

  has_one :subject, through: :classroom

  validates :user, uniqueness: {scope: :classroom_id}

  def self.from_wonde(wonde_class)
    classroom = Classroom.find_by(client_id: wonde_class["id"])

    return if classroom.subject_id.blank?

    enroll_users_to_classroom(wonde_class, classroom)
  end

  class << self
    private

    def enroll_users_to_classroom(wonde_class, classroom)
      # To handle updates to classrooms, delete all existing enrollments and start again
      classroom.enrollments.destroy_all
      create_classroom_enrollments(wonde_class.dig("students", "data"), classroom)
      create_classroom_enrollments(wonde_class.dig("employees", "data"), classroom)
    end

    def create_classroom_enrollments(people, classroom)
      return if people.blank?

      users_by_upi = User.where(upi: people.pluck("upi")).index_by(&:upi)
      people.each do |person|
        student = users_by_upi[person["upi"]]
        next unless student

        create_enrollment(classroom, student)
      end

      classroom.update_attribute(:disabled, !classroom.enrollments.exists?)
    end

    def create_enrollment(classroom, student)
      e = Enrollment.where(classroom: classroom, user: student).first_or_initialize
      e.user = student
      e.classroom = classroom
      e.save!
    end
  end
end
