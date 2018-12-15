class Quiz::CheckAnswer
  def initialize(params)
    @quiz = params[:quiz]
    @question = params[:question]
    @asked_question = AskedQuestion.where(quiz: @quiz).where(question: @question).first
    @answer_given = params[:answer_given]
  end

  def call
    check_answer_correct unless already_answered?

    Quiz::MoveQuizForward.new(quiz: @quiz).call
    Answer.where(question: @question).where(correct: true)
  end

  def already_answered?
    @asked_question.correct.present?
  end

  def check_answer_correct
    if @question.short_answer?
      check_short_answer
    else
      check_multiple_choice
    end

    @asked_question.save
    @question.save
  end

  def check_short_answer
    correct_answer = @question.answers.first.text
    if @answer_given[:short_answer].casecmp(correct_answer).zero?
      process_correct_answer
    else
      process_incorrect_answer
    end
  end

  def check_multiple_choice
    raise 'no valid answer given to multiple choice' if @answer_given[:id].blank?

    @answer = Answer.find_by(id: @answer_given[:id])
    if @answer.correct
      process_correct_answer
    else
      process_incorrect_answer
    end
  end

  def process_correct_answer
    @quiz.answered_correct += 1
    @quiz.streak += 1
    @asked_question.correct = true
    Quiz::AddLeaderboardPoint.new(quiz: @quiz, question: @question).call
  end

  def process_incorrect_answer
    @quiz.streak = 0
    @asked_question.correct = false
  end
end