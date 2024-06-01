# frozen_string_literal: true

HireFire.configure do |config|
  config.dyno(:worker) do
    HireFire::Macro::Delayed::Job.job_queue_size
  end
end
