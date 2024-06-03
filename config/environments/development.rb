# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Provide a default URL host for mailers
  config.action_mailer.default_url_options = { host: 'localhost', port: ENV.fetch('PORT') { 3000 } }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.after_initialize do
    HttpLog.configure do |config|
      config.logger = Rails.logger
      config.color = :red
      config.log_headers = true
    end

    Mail.register_interceptor(
      RecipientInterceptor.new(
        ENV['EMAIL_RECIPIENTS'],
        subject_prefix: '[DEV]'
      )
    )
  end

  # Perform jobs straight away
  config.active_job.queue_adapter = :inline

  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.add_footer = true
    Bullet.skip_html_injection = false

    Bullet.add_safelist type: :unused_eager_loading, class_name: 'Lesson', association: :topic
    Bullet.add_safelist type: :unused_eager_loading, class_name: 'Classroom', association: :subject
    Bullet.add_safelist type: :unused_eager_loading, class_name: 'ActionText::RichText', association: :embeds_attachments
    Bullet.add_safelist type: :unused_eager_loading, class_name: 'Customisation', association: :image_attachment
  end

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true
end
