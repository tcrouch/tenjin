# frozen_string_literal: true

class Question::ImportQuestions < ApplicationCommand
  def initialize(data, topic, filename)
    @json = JSON.parse(data)
    @topic = topic
    @questions_to_import = []
    @name = filename.rpartition(".").first
  end

  def call
    return failure(@error) unless import_json_questions

    success(number_questions_imported: @questions_to_import.count)
  end

  private

  def import_json_questions
    @json.each do |question|
      @question = question
      return false unless validate_question
      return false unless build_question
    end

    @questions_to_import.each(&:save)
    @topic.update_attribute(:name, @name)
    true
  end

  def build_question
    @question["answers_attributes"] = @question["answers"]
    @question = @question.except("answers")
    return false unless find_or_create_lesson

    question_to_import = Question.new(@question)
    question_to_import.topic = @topic
    question_to_import.lesson = @lesson unless @lesson.nil?

    if question_to_import.valid?
      @questions_to_import.push(question_to_import)
    else
      record_error(question_to_import.errors.full_messages.join(", "))
    end
  end

  def find_or_create_lesson
    @lesson = nil
    return true if @question["lesson"].nil?

    @lesson = Lesson.find_or_create_by(title: @question["lesson"], topic: @topic)
    return record_error(@lesson.errors.full_messages.join(", ")) unless @lesson.valid?

    @question = @question.except("lesson")
  end

  def validate_question
    unless %w[question_type answers question_text].all? { |s| @question.key?(s) }
      return record_error("Question missing key")
    end

    validate_answers
  end

  def validate_answers
    answers = @question["answers"]
    return record_error("Answers for question not in array") unless answers.respond_to?(:each)

    answers.each do |a|
      return record_error("Text key missing for answer") unless a.key?("text")
    end

    true
  end

  def record_error(error)
    @error = "#{error}: #{@question}"
    false
  end
end
