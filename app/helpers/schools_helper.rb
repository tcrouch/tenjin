# frozen_string_literal: true

# Renders a school's roster sync state for the admin schools table
module SchoolsHelper
  # Badge colour and icon for each sync status; the wording is School#sync_status_label
  SYNC_STATUS_BADGES = {
    "never" => ["secondary", nil],
    "queued" => ["secondary", "fa-clock"],
    "syncing" => ["info", "fa-sync fa-spin"],
    "successful" => ["success", "fa-check"],
    "failed" => ["danger", "fa-times"],
    "needed" => ["warning", "fa-exclamation-triangle"]
  }.freeze
  STALLED_SYNC_BADGE = ["warning", "fa-hourglass-end"].freeze
  UNKNOWN_STATUS_BADGE = ["secondary", "fa-question"].freeze

  def sync_status_badge(school)
    colour, icon = school.sync_stalled? ? STALLED_SYNC_BADGE : SYNC_STATUS_BADGES.fetch(school.sync_status, UNKNOWN_STATUS_BADGE)
    badge = tag.span(class: "badge text-bg-#{colour}") do
      safe_join([icon && tag.i(class: "fas #{icon} me-1", aria: {hidden: true}), school.sync_status_label].compact)
    end
    # Re-adding a school resets its status to never without clearing the date
    return badge if school.never? || school.last_sync.nil?

    safe_join([badge, tag.small("Last synced #{school.last_sync.strftime("%-d %b %Y")}", class: "d-block text-body-secondary mt-1")])
  end
end
