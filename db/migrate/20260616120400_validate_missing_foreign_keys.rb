# frozen_string_literal: true

# Validates the foreign keys added unvalidated by AddMissingForeignKeys.
# VALIDATE CONSTRAINT takes only a SHARE UPDATE EXCLUSIVE lock, so reads and
# writes continue.
class ValidateMissingForeignKeys < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  # Mirrors AddMissingForeignKeys::FOREIGN_KEYS (kept standalone).
  FOREIGN_KEYS = [
    [:users, :schools, :school_id],
    [:classrooms, :schools, :school_id],
    [:classrooms, :subjects, :subject_id],
    [:quizzes, :subjects, :subject_id],
    [:lessons, :topics, :topic_id],
    [:asked_questions, :questions, :question_id],
    [:asked_questions, :quizzes, :quiz_id],
    [:topics, :lessons, :default_lesson_id]
  ].freeze

  def up
    FOREIGN_KEYS.each do |from_table, to_table, column|
      validate_foreign_key from_table, to_table, column: column
    end
  end

  def down
    # Validation state cannot be reverted without dropping the FK — no-op.
  end
end
