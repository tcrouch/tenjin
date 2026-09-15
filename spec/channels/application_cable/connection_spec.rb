# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection, :default_creates do
  def warden_with(user)
    instance_double(Warden::Proxy, user: user)
  end

  it "identifies the connection by the signed-in user" do
    connect "/cable", env: {"warden" => warden_with(student)}
    expect(connection.current_user).to eq(student)
  end

  it "rejects a handshake with no signed-in user" do
    expect { connect "/cable", env: {"warden" => warden_with(nil)} }.to have_rejected_connection
  end

  it "rejects a user who is no longer active" do
    disabled_student = build_stubbed(:student, disabled: true)
    expect { connect "/cable", env: {"warden" => warden_with(disabled_student)} }.to have_rejected_connection
  end
end
