# frozen_string_literal: true

namespace :migrations do
  desc 'Migrate data'
  task usage_statistic_questions: :environment do
    # Set start date for collecting statistics to the start of the year.
    start_date = Date.parse('Jan 6 2020')
    UsageStatistic.find_each do |us|
      user_statistic = UserStatistic.create_or_find_by(
        user: us.user,
        week_beginning: start_date
      )
      user_statistic.increment!(:questions_answered, us.questions_answered) unless us.questions_answered.blank?
    end
  end
end
