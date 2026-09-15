# frozen_string_literal: true

# Pushes a user's fresh subject and topic scores to the live leaderboards their school streams
class Leaderboard::BroadcastLeaderboardPoint < ApplicationService
  def initialize(topic, user)
    @topic = topic
    @user = user
  end

  def call
    @subject_score, @topic_score = scores
    LeaderboardChannel.broadcast_to(LeaderboardChannel.leaderboard_for(@topic.subject, @user.school), json_data)
  end

  protected

  def json_data
    {
      id: @user.id,
      name: "#{@user.forename} #{@user.surname[0]}",
      school_name: @user.school.name,
      topic: @topic.id,
      topic_score: @topic_score,
      subject_score: @subject_score,
      classroom_names: @user.classrooms.pluck(:name)
    }
  end

  def scores
    TopicScore.joins(:topic)
      .where(user_id: @user)
      .where(subject_topics.arel.exists)
      .pick(s_score.as("subject_score"), t_score.as("topic_score"))
  end

  private

  def s_score
    TopicScore.arel_table[:score].sum
  end

  def t_score
    TopicScore.select(s_score)
      .where(user_id: @user, topic_id: @topic)
      .arel
  end

  def subject_topics
    Topic.select(1)
      .from("topics t2")
      .where(t2: {id: @topic})
      .where("t2.subject_id = topics.subject_id")
  end
end
