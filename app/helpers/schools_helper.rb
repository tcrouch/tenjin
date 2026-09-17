# frozen_string_literal: true

# Renders a school's roster sync state for the admin schools table
module SchoolsHelper
  # Label, badge colour and icon for each sync status
  SYNC_STATUS_BADGES = {
    "never" => ["Never synced", "secondary", nil],
    "queued" => ["Queued", "secondary", "fa-clock"],
    "syncing" => ["Syncing", "info", "fa-sync fa-spin"],
    "successful" => ["Synced", "success", "fa-check"],
    "failed" => ["Failed", "danger", "fa-times"],
    "needed" => ["Sync needed", "warning", "fa-exclamation-triangle"]
  }.freeze
  STALLED_SYNC_BADGE = ["Sync timed out", "warning", "fa-hourglass-end"].freeze
  UNKNOWN_STATUS_BADGE = ["Unknown", "secondary", "fa-question"].freeze

  def sync_status_badge(school)
    label, colour, icon =
      school.sync_stalled? ? STALLED_SYNC_BADGE : SYNC_STATUS_BADGES.fetch(school.sync_status, UNKNOWN_STATUS_BADGE)
    badge = tag.span(class: "badge text-bg-#{colour}") do
      safe_join([icon && tag.i(class: "fas #{icon} me-1", aria: {hidden: true}), label].compact)
    end
    # Re-adding a school resets its status to never without clearing the date
    return badge if school.never? || school.last_sync.nil?

    safe_join([badge, tag.small("Last synced #{school.last_sync.strftime("%-d %b %Y")}", class: "d-block text-body-secondary mt-1")])
  end
end
