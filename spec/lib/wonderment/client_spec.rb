# frozen_string_literal: true

require "rails_helper"

RSpec.describe Wonderment::Client do
  subject(:client) { described_class.new("a-token") }

  let(:resource_url) { "https://api.wonde.com/v1.0/schools/S1" }
  let(:first_page_url) do
    "https://api.wonde.com/v1.0/schools/S1/classes?cursor=true&include=students,employees&per_page=50"
  end
  let(:second_page_url) do
    "https://api.wonde.com/v1.0/schools/S1/classes?cursor=eyJtaXNfY2xhc3Nlcy5pZCI6MX0&include=students%2Cemployees&per_page=50"
  end

  def page(records, next_url)
    {"data" => records,
     "meta" => {"pagination" => {"next" => next_url, "more" => !next_url.nil?}}}.to_json
  end

  describe "#get" do
    before { stub_request(:get, resource_url).to_return(body: {"data" => {"id" => "S1"}}.to_json) }

    it "returns the data payload" do
      expect(client.get("schools/S1")).to eq({"id" => "S1"})
    end

    it "authenticates as the bearer of the token" do
      client.get("schools/S1")

      expect(a_request(:get, resource_url)
        .with(headers: {"Authorization" => "Bearer a-token"})).to have_been_made
    end

    # Net::HTTP negotiates its own Accept-Encoding and decompresses the reply. Setting the
    # header to a bare "gzip", as Wonde's curl example does, leaves the body compressed.
    it "leaves Accept-Encoding to the adapter" do
      client.get("schools/S1")

      expect(a_request(:get, resource_url)
        .with { |req| req.headers["Accept-Encoding"] != "gzip" }).to have_been_made
    end
  end

  describe "#each_page" do
    before do
      stub_request(:get, first_page_url).to_return(body: page([{"id" => "A"}, {"id" => "B"}], second_page_url))
      stub_request(:get, second_page_url).to_return(body: page([{"id" => "C"}], nil))
    end

    it "yields every record across every page" do
      records = []
      client.each_page("schools/S1/classes", include: %w[students employees]) { |r| records << r }

      expect(records).to contain_exactly({"id" => "A"}, {"id" => "B"}, {"id" => "C"})
    end

    # Offset paging shifts when the MIS gains a class mid-sync, so a later page can skip
    # pupils; they then miss the roster and finish_sync disables them. A cursor holds its
    # place in a stable key order instead.
    it "asks for cursor paging" do
      client.each_page("schools/S1/classes", include: %w[students employees]) { nil }

      expect(a_request(:get, first_page_url)).to have_been_made
    end

    it "stops once a page reports no more" do
      client.each_page("schools/S1/classes", include: %w[students employees]) { nil }

      expect(a_request(:get, second_page_url)).to have_been_made.once
    end

    # The whole reason this client exists: a roster must not accumulate in the worker
    it "releases each page before reaching the next" do
      probe = ObjectSpace::WeakMap.new
      seen = 0
      first_page_retained = nil

      client.each_page("schools/S1/classes", include: %w[students employees]) do |record|
        seen += 1
        probe[record] = true if seen == 1
        next unless seen == 3

        2.times { GC.start(full_mark: true, immediate_sweep: true) }
        first_page_retained = probe.size.positive?
      end

      expect(first_page_retained).to be false
    end
  end

  describe "error responses" do
    {400 => Wonderment::Error::BadRequest,
     401 => Wonderment::Error::Unauthorized,
     403 => Wonderment::Error::Forbidden,
     404 => Wonderment::Error::NotFound,
     422 => Wonderment::Error::UnprocessableEntity,
     423 => Wonderment::Error::SchoolInactive,
     429 => Wonderment::Error::TooManyRequests,
     500 => Wonderment::Error::ServerError,
     503 => Wonderment::Error::ServiceUnavailable}.each do |status, error_class|
      it "raises #{error_class.name.split("::").last} on #{status}" do
        stub_request(:get, resource_url).to_return(status: status)

        expect { client.get("schools/S1") }.to raise_error(error_class)
      end
    end

    it "carries the status and body for a rescuer to inspect" do
      stub_request(:get, resource_url).to_return(status: 422, body: "invalid include")

      expect { client.get("schools/S1") }
        .to raise_error(an_object_having_attributes(status: 422, body: "invalid include"))
    end

    it "raises the base error on a status it does not map" do
      stub_request(:get, resource_url).to_return(status: 418)

      expect { client.get("schools/S1") }.to raise_error(Wonderment::Error)
    end
  end
end
