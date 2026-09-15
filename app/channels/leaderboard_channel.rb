# frozen_string_literal: true

# Streams live leaderboard points for a subject to the viewer's school, or its school group
class LeaderboardChannel < ApplicationCable::Channel
  def self.leaderboard_for(subject_id, school)
    ["subject-#{subject_id}", school.leaderboard_scope]
  end

  def subscribed
    subject_id = Subject.where(id: params[:subject_id]).pick(:id)
    return reject if subject_id.nil?

    stream_for self.class.leaderboard_for(subject_id, current_user.school)
  end
end
