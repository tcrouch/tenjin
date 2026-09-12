# frozen_string_literal: true

# Sets defaults on nullable boolean/integer columns and backfills their NULLs.
# The default goes on first so rows inserted during the backfill already get
# it; the backfill is batched to keep row locks short.
class BackfillNullableDataColumns < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  BATCH_SIZE = 5_000

  # [table, column, default]. asked_questions.correct is intentionally absent:
  # NULL there means "asked, not yet answered" (Quiz::CheckAnswer).
  BACKFILLS = [
    [:users, :disabled, false],
    [:classrooms, :disabled, false],
    [:quizzes, :active, false],
    [:quizzes, :counts_for_leaderboard, false],
    [:challenges, :daily, false],
    [:answers, :correct, false],
    [:homework_progresses, :completed, false],
    [:homework_progresses, :progress, 0]
  ].freeze

  def up
    execute "SET lock_timeout TO '10s'"

    BACKFILLS.each do |table, column, default|
      change_column_default table, column, default
      backfill_nulls(table, column, default)
    end
  end

  def down
    BACKFILLS.each do |table, column, _default|
      change_column_default table, column, nil
    end
  end

  private

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
