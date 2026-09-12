# frozen_string_literal: true

# Sets a default of 0 on the counter_cache columns (previously nullable with no
# default) and recomputes any that differ from their source rows. Each
# statement autocommits so no lock outlives the statement that needs it.
class BackfillCounterCaches < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  # [table, counter_column, child_table, foreign_key]
  COUNTERS = [
    [:classrooms, :enrollments_count, :enrollments, :classroom_id],
    [:questions, :flagged_questions_count, :flagged_questions, :question_id],
    [:lessons, :questions_count, :questions, :lesson_id]
  ].freeze

  def up
    execute "SET lock_timeout TO '10s'"

    COUNTERS.each do |table, counter_column, child_table, foreign_key|
      change_column_default table, counter_column, 0

      count = "(SELECT COUNT(*) FROM #{child_table} WHERE #{child_table}.#{foreign_key} = #{table}.id)"
      execute(<<~SQL.squish)
        UPDATE #{table} SET #{counter_column} = #{count}
        WHERE #{counter_column} IS DISTINCT FROM #{count}
      SQL
    end
  end

  def down
    COUNTERS.each do |table, counter_column, _child_table, _foreign_key|
      change_column_default table, counter_column, nil
    end
  end
end
