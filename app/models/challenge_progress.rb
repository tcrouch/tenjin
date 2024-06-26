# frozen_string_literal: true

class ChallengeProgress < ApplicationRecord
  belongs_to :challenge
  belongs_to :user

  validates :user, uniqueness: {scope: :challenge_id}
end
