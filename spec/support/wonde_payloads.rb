# frozen_string_literal: true

# Wonde payloads in the shape the client parses, for stubbing the API in specs
module WondePayloads
  def wonde_page(records, next_url = nil)
    {"data" => records,
     "meta" => {"pagination" => {"next" => next_url, "more" => !next_url.nil?}}}.to_json
  end

  def wonde_class(id, subject: {"data" => {"id" => "SUBJ", "name" => "Sociology"}}, students: [], employees: [])
    {"id" => id, "name" => "Class #{id}", "code" => nil, "description" => nil, "subject" => subject,
     "students" => {"data" => students}, "employees" => {"data" => employees}}
  end

  def wonde_person(upi: SecureRandom.hex, forename: FFaker::Name.first_name, surname: FFaker::Name.last_name)
    {"id" => SecureRandom.hex, "upi" => upi, "forename" => forename, "surname" => surname}
  end
end
