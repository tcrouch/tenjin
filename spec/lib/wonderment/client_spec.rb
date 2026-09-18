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

  describe "#get" do
    before { stub_request(:get, resource_url).to_return(body: {"data" => {"id" => "S1"}}.to_json) }

    it "returns the data payload" do
      expect(client.get("schools", "S1")).to eq({"id" => "S1"})
    end

    it "authenticates as the bearer of the token" do
      client.get("schools", "S1")

      expect(a_request(:get, resource_url)
        .with(headers: {"Authorization" => "Bearer a-token"})).to have_been_made
    end

    # Ids are typed by admins and stored from Wonde's replies, so each travels as one segment
    it "escapes each path segment" do
      stub_request(:get, "https://api.wonde.com/v1.0/schools/A%2F1").to_return(body: {"data" => {}}.to_json)

      client.get("schools", "A/1")

      expect(a_request(:get, "https://api.wonde.com/v1.0/schools/A%2F1")).to have_been_made
    end

    # An empty id would address the listing above it, a different resource altogether
    it "refuses a blank segment" do
      expect { client.get("schools", "") }.to raise_error(ArgumentError, /blank/)
      expect(a_request(:get, /wonde/)).not_to have_been_made
    end

    # Net::HTTP negotiates its own Accept-Encoding and decompresses the reply. Setting the
    # header to a bare "gzip", as Wonde's curl example does, leaves the body compressed.
    it "leaves Accept-Encoding to the adapter" do
      client.get("schools", "S1")

      expect(a_request(:get, resource_url)
        .with { |req| req.headers["Accept-Encoding"] != "gzip" }).to have_been_made
    end
  end

  describe "#each_page" do
    before do
      stub_request(:get, first_page_url).to_return(body: wonde_page([{"id" => "A"}, {"id" => "B"}], second_page_url))
      stub_request(:get, second_page_url).to_return(body: wonde_page([{"id" => "C"}]))
    end

    it "yields every record across every page" do
      records = []
      client.each_page("schools", "S1", "classes", include: %w[students employees]) { |r| records << r }

      expect(records).to contain_exactly({"id" => "A"}, {"id" => "B"}, {"id" => "C"})
    end

    # Offset paging shifts when the MIS gains a class mid-sync, so a later page can skip
    # pupils; they then miss the roster and finish_sync disables them. A cursor holds its
    # place in a stable key order instead.
    it "asks for cursor paging" do
      client.each_page("schools", "S1", "classes", include: %w[students employees]) { nil }

      expect(a_request(:get, first_page_url)).to have_been_made
    end

    it "stops once a page reports no more" do
      client.each_page("schools", "S1", "classes", include: %w[students employees]) { nil }

      expect(a_request(:get, second_page_url)).to have_been_made.once
    end

    # The whole reason this client exists: a roster must not accumulate in the worker,
    # and the next page's download is the moment the previous one must already be gone
    it "releases a page before fetching the next" do
      probe = ObjectSpace::WeakMap.new
      first_page_retained = nil
      stub_request(:get, second_page_url).to_return do
        2.times { GC.start(full_mark: true, immediate_sweep: true) }
        first_page_retained = probe.size.positive?
        {body: wonde_page([{"id" => "C"}])}
      end

      client.each_page("schools", "S1", "classes", include: %w[students employees]) do |record|
        probe[record] = true if probe.size.zero?
      end

      expect(first_page_retained).to be false
    end

    it "fetches no page beyond what an enumerator consumes" do
      records = client.each_page("schools", "S1", "classes", include: %w[students employees]).first(2)

      expect(records).to eq([{"id" => "A"}, {"id" => "B"}])
      expect(a_request(:get, second_page_url)).not_to have_been_made
    end

    # A walk that ends early leaves everyone on the unread pages off the roster, and the
    # sync then disables them, so a page that cannot be followed must fail loudly
    {"a nil next URL" => {"more" => true, "next" => nil},
     "an empty next URL" => {"more" => true, "next" => ""},
     "no next URL" => {"more" => true}}.each do |description, pagination|
      it "raises when a page promises more with #{description}" do
        stub_request(:get, first_page_url)
          .to_return(body: {"data" => [], "meta" => {"pagination" => pagination}}.to_json)

        expect { client.each_page("schools", "S1", "classes", include: %w[students employees]) { nil } }
          .to raise_error(Wonderment::Error, /promises more/)
      end
    end

    # The bearer token goes with every request, so a next URL is followed only within the API
    it "refuses a next URL that leads off the API" do
      stub_request(:get, first_page_url)
        .to_return(body: wonde_page([{"id" => "A"}], "https://elsewhere.example/v1.0/schools/S1/classes?cursor=x"))

      expect { client.each_page("schools", "S1", "classes", include: %w[students employees]) { nil } }
        .to raise_error(Wonderment::Error, /outside/)
      expect(a_request(:get, /elsewhere/)).not_to have_been_made
    end

    it "raises when a page carries no pagination" do
      stub_request(:get, first_page_url).to_return(body: {"data" => []}.to_json)

      expect { client.each_page("schools", "S1", "classes", include: %w[students employees]) { nil } }
        .to raise_error(Wonderment::Error, /no pagination/)
    end
  end

  describe "failed requests" do
    it "raises on an error status" do
      stub_request(:get, resource_url).to_return(status: 503)

      expect { client.get("schools", "S1") }.to raise_error(Wonderment::Error, "Wonde responded 503")
    end

    it "carries the status and body for a rescuer to inspect" do
      stub_request(:get, resource_url).to_return(status: 422, body: "invalid include")

      expect { client.get("schools", "S1") }
        .to raise_error(an_object_having_attributes(status: 422, body: "invalid include"))
    end

    # Transport failures surface as the same error, so nothing outside lib needs to know Faraday
    it "raises when Wonde does not answer in time" do
      stub_request(:get, resource_url).to_timeout

      expect { client.get("schools", "S1") }.to raise_error(Wonderment::Error, /did not answer/)
    end

    it "raises when Wonde cannot be reached" do
      stub_request(:get, resource_url).to_raise(Errno::ECONNREFUSED)

      expect { client.get("schools", "S1") }.to raise_error(Wonderment::Error, /did not answer/)
    end

    # A proxy's maintenance page comes back 200 and as HTML
    it "raises when the reply is not JSON" do
      stub_request(:get, resource_url).to_return(body: "<html>Down for maintenance</html>")

      expect { client.get("schools", "S1") }.to raise_error(Wonderment::Error, /not JSON/)
    end

    it "raises when the reply carries no data payload" do
      stub_request(:get, resource_url).to_return(body: {"error" => "nothing here"}.to_json)

      expect { client.get("schools", "S1") }.to raise_error(Wonderment::Error, /data payload/)
    end
  end
end
