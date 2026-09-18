# frozen_string_literal: true

module Wonderment
  # Raised when Wonde answers with an error status or does not answer at all.
  class Error < StandardError
    attr_reader :status, :body

    def initialize(message, status: nil, body: nil)
      @status = status
      @body = body
      super(message)
    end
  end
end
