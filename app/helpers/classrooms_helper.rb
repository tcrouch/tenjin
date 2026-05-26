# frozen_string_literal: true

module ClassroomsHelper
  def student_homeworks(student, homework_progress)
    entries = homework_progress.find_all { |hp| hp.user_id == student.id }
    entries.take(5).map! { |e| boolean_icon(e.completed?) }.join
  end

  def sync_status_button
    case @school.sync_status
    when "never", "successful"
      sync_button
    when "failed", "needed"
      sync_needed_button
    when "syncing"
      if (Time.current - @school.updated_at) < 240
        sync_timeout_button
      else
        "Refresh the page to see the current sync status"
      end
    else
      "Refresh the page to see the current sync status"
    end
  end

  def report_progress(homework)
    count = homework.count
    return "0 / 0 - 0%" if count.zero?

    percent = number_to_percentage(homework.completed_count / count.to_f * 100, precision: 0)
    "#{homework.completed_count} / #{count} - #{percent}"
  end

  def sync_button
    link_to "Sync Classrooms & Users", sync_school_path(current_user.school),
      method: :patch,
      id: "syncButton",
      class: "btn btn-primary btn-block my-3"
  end

  def sync_needed_button
    link_to "School sync required. Click here to start.",
      sync_school_path(current_user.school),
      method: :patch,
      id: "syncButton",
      class: "btn btn-danger btn-block my-3"
  end

  def sync_timeout_button
    link_to "Last Sync Timed Out.  Press here to try again.", sync_school_path(current_user.school),
      method: :patch,
      id: "syncButton",
      class: "btn btn-secondary btn-block my-3"
  end
end
