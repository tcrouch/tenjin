# frozen_string_literal: true

class Customisation < ApplicationRecord
  enum :customisation_type, {dashboard_style: 0, leaderboard_icon: 1, subject_image: 2}

  has_many :customisation_unlocks
  has_many :active_customisations

  has_one_attached :image

  # Only the original blob is ever linked, so the variant preloads in with_attached_image would go unused
  scope :preload_image, -> { includes(image_attachment: :blob) }

  before_save :make_unpurchasable_if_retired

  validates :cost, presence: true
  validates :name, presence: true
  validates :value, presence: true
  validates :image, presence: true, if: :dashboard_style?

  # Checks retired too: update_all writes skip make_unpurchasable_if_retired
  def for_sale?
    purchasable? && !retired?
  end

  def make_unpurchasable_if_retired
    return unless retired?

    self.purchasable = false
    self.sticky = false
  end
end
