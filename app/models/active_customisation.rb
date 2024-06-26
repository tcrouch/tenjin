# frozen_string_literal: true

class ActiveCustomisation < ApplicationRecord
  belongs_to :customisation
  belongs_to :user

  validates :user, uniqueness: {scope: :customisation_id}
  validates :customisation, presence: true
end
