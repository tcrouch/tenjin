# frozen_string_literal: true

# Adds foreign keys for relationships that lacked them. Each is added NOT VALID
# so existing rows are not scanned (ValidateMissingForeignKeys does that), and
# each statement autocommits so the two-table lock it takes lasts milliseconds
# rather than accumulating across all eight.
class AddMissingForeignKeys < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  # [from_table, to_table, options]
  FOREIGN_KEYS = [
    [:users, :schools, {column: :school_id}],
    [:classrooms, :schools, {column: :school_id}],
    [:classrooms, :subjects, {column: :subject_id}],
    [:quizzes, :subjects, {column: :subject_id}],
    [:lessons, :topics, {column: :topic_id}],
    [:asked_questions, :questions, {column: :question_id}],
    [:asked_questions, :quizzes, {column: :quiz_id}],
    # default_lesson is optional: deleting the lesson clears the pointer
    # instead of blocking Lesson#destroy and Topic#destroy.
    [:topics, :lessons, {column: :default_lesson_id, on_delete: :nullify}]
  ].freeze

  def up
    execute "SET lock_timeout TO '10s'"

    FOREIGN_KEYS.each do |from_table, to_table, options|
      add_foreign_key from_table, to_table, validate: false, if_not_exists: true, **options
    end
  end

  def down
    FOREIGN_KEYS.each do |from_table, to_table, options|
      remove_foreign_key from_table, to_table, column: options[:column], if_exists: true
    end
  end
end
