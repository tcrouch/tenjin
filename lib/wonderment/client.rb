# frozen_string_literal: true

module Wonderment
  # Reads the Wonde REST API, holding one page of a listing at a time.
  class Client
    BASE_URL = "https://api.wonde.com/v1.0/"

    # Wonde's own default. Each page is held whole, so a larger one buys fewer
    # round trips at a proportional cost in peak memory.
    PAGE_SIZE = 50

    TIMEOUT = 30

    def initialize(token, base_url: BASE_URL)
      @token = token
      @base_url = base_url
    end

    # The `data` payload of a single resource.
    def get(path, **params)
      request(url_for(path, params)).fetch("data")
    end

    # Yields every record of a listing, fetching pages as it goes and keeping none.
    def each_page(path, **params)
      url = url_for(path, params.merge(per_page: PAGE_SIZE))

      while url
        body = request(url)
        body.fetch("data").each { |record| yield record }
        url = next_page_url(body)
      end
    end

    private

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
      raise Error.for(response.status, response.body) unless response.success?

      JSON.parse(response.body)
    end

    def url_for(path, params)
      query = params.compact.transform_values { |value| Array(value).join(",") }
      return "#{@base_url}#{path}" if query.empty?

      "#{@base_url}#{path}?#{URI.encode_www_form(query)}"
    end

    # Wonde's next URL repeats the original include and per_page, so it is followed as given
    def next_page_url(body)
      pagination = body.dig("meta", "pagination")
      return unless pagination && pagination["more"]

      pagination["next"]
    end
  end
end
