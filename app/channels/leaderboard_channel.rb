# frozen_string_literal: true

# Streams live leaderboard points for a subject to the viewer's school, or its school group
class LeaderboardChannel < ApplicationCable::Channel
  def self.leaderboard_for(subject, school)
    [subject, school.school_group || school]
  end

  def subscribed
    subject = Subject.find_by(id: params[:subject_id])
    return reject if subject.nil?

    stream_for self.class.leaderboard_for(subject, current_user.school)
  end
end
