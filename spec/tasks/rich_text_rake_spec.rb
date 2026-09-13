# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "rich_text rake tasks" do
  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("rich_text:resign_attachment_sgids") }

  around do |example|
    previous = ENV.delete("OLD_SECRET_KEY_BASE")
    example.run
  ensure
    ENV["OLD_SECRET_KEY_BASE"] = previous if previous
  end

  def run_task(name)
    Rake::Task[name].tap(&:reenable).invoke
  end

  describe "rich_text:resign_attachment_sgids" do
    it "runs with the current secret when OLD_SECRET_KEY_BASE is unset" do
      expect { run_task("rich_text:resign_attachment_sgids") }.to output(/re-signed 0/).to_stdout
    end
  end

  describe "rich_text:downgrade_attachment_sgids" do
    it "signs for the current secret when OLD_SECRET_KEY_BASE is unset" do
      expect { run_task("rich_text:downgrade_attachment_sgids") }.to output(/re-signed 0/).to_stdout
    end

    it "runs when OLD_SECRET_KEY_BASE is set" do
      ENV["OLD_SECRET_KEY_BASE"] = Rails.application.secret_key_base
      expect { run_task("rich_text:downgrade_attachment_sgids") }.to output(/re-signed 0/).to_stdout
    end
  end
end
