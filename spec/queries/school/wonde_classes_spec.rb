# frozen_string_literal: true

require "rails_helper"

# Paging and transport belong to Wonderment::Client and are covered by its spec;
# what matters here is that the school asks Wonde for the right thing.
RSpec.describe School::WondeClasses do
  let(:school) { create(:school, client_id: "A852030759", token: "a-token") }
  let(:classes_url) do
    "https://api.wonde.com/v1.0/schools/A852030759/classes?cursor=true&include=students,employees&per_page=50"
  end

  before do
    stub_request(:get, classes_url).to_return(body: wonde_page([{"id" => "C1"}, {"id" => "C2"}]))
  end

  it "yields the classes listed for the school" do
    expect(described_class.new(school).to_a).to contain_exactly({"id" => "C1"}, {"id" => "C2"})
  end

  it "asks for the people in each class" do
    described_class.new(school).each { nil }

    expect(a_request(:get, classes_url)).to have_been_made
  end
end
