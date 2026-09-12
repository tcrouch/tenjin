# frozen_string_literal: true

# Enforces NOT NULL on columns backing required associations and on the
# backfilled boolean/counter columns.
#
# Each column gets a NOT VALID CHECK constraint first, which rejects new NULLs
# from that point on. The backfilled columns are then swept once more, because
# app servers that booted before BackfillNullableDataColumns and
# BackfillCounterCaches ran carry the old NULL defaults in their schema cache
# and insert explicit NULLs until they are cycled. Validating the CHECK lets
# Postgres set NOT NULL without a full table scan; the CHECK is then redundant.
#
# Every step is idempotent so a rerun after a lock timeout resumes cleanly.
class EnforceNotNullConstraints < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  BATCH_SIZE = 5_000

  # Columns backing belongs_to associations without optional: true.
  REQUIRED_ASSOCIATIONS = [
    [:all_time_topic_scores, :topic_id],
    [:all_time_topic_scores, :user_id],
    [:answers, :question_id],
    [:asked_questions, :question_id],
    [:asked_questions, :quiz_id],
    [:challenges, :topic_id],
    [:classroom_winners, :classroom_id],
    [:classroom_winners, :user_id],
    [:classrooms, :school_id],
    [:enrollments, :classroom_id],
    [:enrollments, :user_id],
    [:homework_progresses, :homework_id],
    [:homework_progresses, :user_id],
    [:homeworks, :classroom_id],
    [:homeworks, :topic_id],
    [:leaderboard_awards, :school_id],
    [:leaderboard_awards, :subject_id],
    [:leaderboard_awards, :user_id],
    [:lessons, :topic_id],
    [:questions, :topic_id],
    [:quizzes, :subject_id],
    [:quizzes, :user_id],
    [:topics, :subject_id],
    [:users, :school_id]
  ].freeze

  # [table, column, default]. Mirrors BackfillNullableDataColumns and
  # BackfillCounterCaches (kept standalone).
  BACKFILLED = [
    [:users, :disabled, false],
    [:classrooms, :disabled, false],
    [:classrooms, :enrollments_count, 0],
    [:quizzes, :active, false],
    [:quizzes, :counts_for_leaderboard, false],
    [:challenges, :daily, false],
    [:answers, :correct, false],
    [:homework_progresses, :completed, false],
    [:homework_progresses, :progress, 0],
    [:questions, :flagged_questions_count, 0],
    [:lessons, :questions_count, 0]
  ].freeze

  def up
    execute "SET lock_timeout TO '10s'"

    REQUIRED_ASSOCIATIONS.each do |table, column|
      enforce_not_null(table, column)
    end
    BACKFILLED.each do |table, column, default|
      enforce_not_null(table, column, backfill: default)
    end
  end

  def down
    (REQUIRED_ASSOCIATIONS + BACKFILLED).each do |table, column, _default|
      change_column_null table, column, true
    end
  end

  private

  def enforce_not_null(table, column, backfill: nil)
    return if connection.columns(table).find { |c| c.name == column.to_s }&.null == false

    constraint_name = "#{table}_#{column}_not_null"
    expression = "#{connection.quote_column_name(column)} IS NOT NULL"

    unless check_constraint_exists?(table, name: constraint_name)
      add_check_constraint table, expression, name: constraint_name, validate: false
    end
    backfill_nulls(table, column, backfill) unless backfill.nil?
    validate_check_constraint table, name: constraint_name
    change_column_null table, column, false
    remove_check_constraint table, name: constraint_name
  end

  def backfill_nulls(table, column, value)
    table_name = connection.quote_table_name(table)
    column_name = connection.quote_column_name(column)
    quoted_value = connection.quote(value)

    loop do
      affected = connection.update(<<~SQL.squish)
        UPDATE #{table_name}
        SET #{column_name} = #{quoted_value}
        WHERE id IN (
          SELECT id FROM #{table_name} WHERE #{column_name} IS NULL LIMIT #{BATCH_SIZE}
        )
      SQL
      break if affected.zero?
    end
  end
end
