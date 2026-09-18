# frozen_string_literal: true

class Enrollment < ApplicationRecord
  belongs_to :user
  # School#start_sync and .from_wonde write enrollments_count themselves, bypassing this callback
  belongs_to :classroom, counter_cache: true

  has_one :subject, through: :classroom

  validates :user, uniqueness: {scope: :classroom_id}

  # Enrolls everyone the Wonde class lists who has an account. A sync calls this once per class
  # after start_sync has emptied the school's enrollments, so the rows go in with one insert.
  def self.from_wonde(wonde_class, classroom)
    upis = %w[students employees].flat_map { |people| wonde_class.dig(people, "data").to_a.pluck("upi") }
    rows = User.where(upi: upis).pluck(:id).map { |user_id| {classroom_id: classroom.id, user_id: user_id} }
    enrolled = rows.empty? ? 0 : insert_all(rows, unique_by: %i[classroom_id user_id]).length
    classroom.update_columns(enrollments_count: enrolled, disabled: enrolled.zero?)
  end
end
