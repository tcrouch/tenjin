# frozen_string_literal: true

class School::AddSchool < ApplicationService
  def initialize(school_params)
    @school_id = school_params[:client_id]
    @client_token = school_params[:token]
  end

  def call
    # The id is typed by an admin, so it is escaped to stay one path segment whatever it holds
    school_from_client = Wonderment::Client.new(@client_token).get("schools/#{ERB::Util.url_encode(@school_id)}")
    school = School.from_wonde(school_from_client, @client_token)
    school.permitted = true
    school.save!
    school
  end
end
