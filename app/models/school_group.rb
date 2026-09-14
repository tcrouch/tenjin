# frozen_string_literal: true

# A named set of schools whose students share a leaderboard
class SchoolGroup < ApplicationRecord
  has_many :schools, dependent: :restrict_with_error

  validates :name, presence: true
end
