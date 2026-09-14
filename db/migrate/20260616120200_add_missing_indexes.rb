# frozen_string_literal: true

# Adds missing indexes, built concurrently to avoid blocking writes.
#
# Deliberately no if_not_exists: a failed concurrent build leaves an INVALID
# index behind, and a rerun must fail on it rather than skip it silently.
class AddMissingIndexes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    execute "SET lock_timeout TO '10s'"

    # FK column that had no supporting index.
    add_index :topics, :default_lesson_id, algorithm: :concurrently

    # Enforces AllTimeTopicScore's (user_id, topic_id) uniqueness in the DB.
    add_index :all_time_topic_scores, %i[user_id topic_id],
      unique: true, algorithm: :concurrently

    # Covered by the leading column of the composite index above.
    remove_index :all_time_topic_scores, :user_id, algorithm: :concurrently
  end

  def down
    add_index :all_time_topic_scores, :user_id, algorithm: :concurrently
    remove_index :all_time_topic_scores, %i[user_id topic_id], algorithm: :concurrently
    remove_index :topics, :default_lesson_id, algorithm: :concurrently
  end
end
