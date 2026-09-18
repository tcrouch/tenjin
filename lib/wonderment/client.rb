# frozen_string_literal: true

# This app's client for the Wonde MIS API
module Wonderment
  # Reads the Wonde REST API, holding one page of a listing at a time.
  class Client
    BASE_URL = "https://api.wonde.com/v1.0/"

    # Wonde's own default. Each page is held whole, so a larger one buys fewer
    # round trips at a proportional cost in peak memory.
    PAGE_SIZE = 50

    # Net::HTTP's own default for each of open, read and write
    TIMEOUT = 60

    def initialize(token, base_url: BASE_URL)
      @token = token
      @base_url = base_url
    end

    # The `data` payload of a single resource, addressed by path segments: get("schools", id)
    def get(*segments, **params)
      request(url_for(segments, params)).fetch("data")
    end

    # Yields every record of a listing, fetching pages as it goes and keeping none.
    #
    # Paging is by cursor: offset paging renumbers its pages when the MIS gains or loses a
    # record mid-walk, and a listing that skips one loses the people on it.
    def each_page(*segments, **params)
      return enum_for(__method__, *segments, **params) unless block_given?

      url = url_for(segments, params.merge(per_page: PAGE_SIZE, cursor: true))
      while url
        url = yield_page(url) { |record| yield record }
      end
    end

    private

    # Holds the page only for the length of this call, so nothing of it survives into the next fetch
    def yield_page(url)
      body = request(url)
      next_url = next_page_url(body)
      body.fetch("data").each { |record| yield record }
      next_url
    end

    def connection
      @connection ||= Faraday.new do |faraday|
        faraday.options.timeout = TIMEOUT
        faraday.adapter :net_http
      end
    end

    def request(url)
      response = connection.get(url) do |req|
        req.headers["Authorization"] = "Bearer #{@token}"
        req.headers["User-Agent"] = "tenjin"
        # Accept-Encoding is left unset deliberately. Net::HTTP asks for gzip by
        # itself and decompresses the reply; naming the header here, as Wonde's
        # curl example does, switches that off and hands back compressed bytes.
      end
      unless response.success?
        raise Error.new("Wonde responded #{response.status}", status: response.status, body: response.body)
      end

      payload(response)
    rescue Faraday::Error => e
      raise Error, "Wonde did not answer: #{e.message}"
    end

    # Every Wonde reply wraps its resource or listing in data; anything else is not Wonde talking
    def payload(response)
      body = JSON.parse(response.body)
      return body if body.is_a?(Hash) && body.key?("data")

      raise Error.new("Wonde answered without a data payload", status: response.status, body: response.body)
    rescue JSON::ParserError
      raise Error.new("Wonde answered with something not JSON", status: response.status, body: response.body)
    end

    def url_for(segments, params)
      path = segments.map { |segment| path_segment(segment) }.join("/")
      query = params.compact.transform_values { |value| Array(value).join(",") }
      return "#{@base_url}#{path}" if query.empty?

      "#{@base_url}#{path}?#{URI.encode_www_form(query)}"
    end

    # A blank segment would address the listing above it, a different resource altogether
    def path_segment(segment)
      raise ArgumentError, "blank path segment" if segment.to_s.strip.empty?

      URI.encode_uri_component(segment.to_s)
    end

    # Wonde's next URL repeats the original include and per_page, so it is followed as given.
    # A page that cannot be followed raises: ending the walk early would leave everyone on the
    # unread pages off the roster, and a sync then disables them.
    def next_page_url(body)
      pagination = body.dig("meta", "pagination")
      raise Error.new("Wonde page carries no pagination", body: body) if pagination.nil?
      return unless pagination["more"]

      next_url = pagination["next"]
      raise Error.new("Wonde page promises more without a next URL", body: body) if next_url.to_s.empty?
      # The bearer token goes with every request, so a URL leading off the API is never followed
      raise Error.new("Wonde page names a next URL outside its API", body: body) unless next_url.start_with?(@base_url)

      next_url
    end
  end
end
