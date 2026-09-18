# frozen_string_literal: true

module Wonderment
  # Raised when the Wonde API answers with an error status.
  class Error < StandardError
    class BadRequest < Error; end

    class Unauthorized < Error; end

    class Forbidden < Error; end

    class NotFound < Error; end

    class UnprocessableEntity < Error; end

    # 423 and the 429/500/503 below are the statuses Wonde documents as worth retrying
    class SchoolInactive < Error; end

    class TooManyRequests < Error; end

    class ServerError < Error; end

    class ServiceUnavailable < Error; end

    STATUSES = {400 => BadRequest, 401 => Unauthorized, 403 => Forbidden, 404 => NotFound,
                422 => UnprocessableEntity, 423 => SchoolInactive, 429 => TooManyRequests,
                500 => ServerError, 503 => ServiceUnavailable}.freeze

    def self.for(status, body)
      STATUSES.fetch(status, self).new(status, body)
    end

    attr_reader :status, :body

    def initialize(status, body)
      @status = status
      @body = body
      super("Wonde responded #{status}")
    end
  end
end
