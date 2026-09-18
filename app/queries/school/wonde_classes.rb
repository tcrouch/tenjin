# frozen_string_literal: true

# The classes Wonde lists for a school, each with the people enrolled in it.
class School::WondeClasses
  include Enumerable

  INCLUDES = %w[students employees].freeze

  def initialize(school)
    @school = school
    @client = Wonderment::Client.new(school.token)
  end

  def each(&block)
    @client.each_page("schools/#{@school.client_id}/classes", include: INCLUDES, &block)
  end
end
