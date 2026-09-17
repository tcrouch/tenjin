# frozen_string_literal: true

require "wondeclient"

# Streams a school's Wonde classes, holding one page at a time.
#
# The gem's own ResultIterator appends every page it fetches to a single array, so a
# whole roster ends up resident at once; a large school's costs hundreds of megabytes.
class School::WondeClasses
  include Enumerable

  # Wonde's own default. Each page is held whole, so a larger one buys fewer
  # round trips at a proportional cost in peak memory.
  PAGE_SIZE = 50

  INCLUDES = %w[students employees].freeze

  def initialize(school)
    @endpoint = Wonde::Client.new(school.token).school(school.client_id).classes
  end

  def each
    url = first_page_url
    while url
      page = JSON.parse(@endpoint.getUrl(url).body)
      page.fetch("data").each { |wonde_class| yield wonde_class }
      url = next_page_url(page)
    end
  end

  private

  def first_page_url
    "#{@endpoint.endpoint}#{@endpoint.uri}?include=#{INCLUDES.join(",")}&per_page=#{PAGE_SIZE}"
  end

  def next_page_url(page)
    pagination = page.dig("meta", "pagination")
    return unless pagination && pagination["more"]

    pagination["next"]
  end
end
