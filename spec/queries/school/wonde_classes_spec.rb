# frozen_string_literal: true

require "rails_helper"

RSpec.describe School::WondeClasses do
  let(:school) { create(:school, client_id: "A852030759", token: "a-token") }
  let(:first_page_url) do
    "https://api.wonde.com/v1.0/schools/A852030759/classes?include=students,employees&per_page=50"
  end
  let(:second_page_url) { "https://api.wonde.com/v1.0/schools/A852030759/classes?page=2" }

  def wonde_class(id)
    {"id" => id, "name" => "SOC #{id}", "code" => nil, "description" => nil, "subject" => "A1",
     "students" => {"data" => []}, "employees" => {"data" => []}}
  end

  def page_body(classes, next_url)
    {"data" => classes,
     "meta" => {"pagination" => {"next" => next_url, "more" => next_url.present?}}}.to_json
  end

  before do
    stub_request(:get, first_page_url)
      .to_return(body: page_body([wonde_class("A1"), wonde_class("A2")], second_page_url))
    stub_request(:get, second_page_url)
      .to_return(body: page_body([wonde_class("A3")], nil))
  end

  it "yields every class from every page" do
    expect(described_class.new(school).to_a)
      .to contain_exactly(wonde_class("A1"), wonde_class("A2"), wonde_class("A3"))
  end

  it "authenticates with the school's token" do
    described_class.new(school).each { nil }

    expect(a_request(:get, first_page_url)
      .with(headers: {"Authorization" => "Bearer a-token"})).to have_been_made
  end

  it "stops requesting once a page reports no more" do
    described_class.new(school).each { nil }

    expect(a_request(:get, second_page_url)).to have_been_made.once
  end

  # The memory ceiling this class exists for: an earlier page must be collectable
  # while a later one is still being walked.
  it "releases each page before reaching the next" do
    probe = ObjectSpace::WeakMap.new
    seen = 0
    first_page_retained = nil

    described_class.new(school).each do |wonde_class|
      seen += 1
      probe[wonde_class] = true if seen == 1
      next unless seen == 3

      2.times { GC.start(full_mark: true, immediate_sweep: true) }
      first_page_retained = probe.size.positive?
    end

    expect(first_page_retained).to be false
  end
end
