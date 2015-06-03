# https://github.com/rails/rails/issues/2639#issuecomment-6591735
class DisableAssetsLogger
  def initialize(app)
    @app = app
    Rails.application.assets.logger = Logger.new('/dev/null')
  end

  def call(env)
    previous_level = Rails.logger.level
    Rails.logger.level = Logger::ERROR if env['PATH_INFO'].index("/assets/") == 0
    @app.call(env)
  ensure
    Rails.logger.level = previous_level
  end
end

Rails.application.configure do
  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  config.cache_store = :redis_store, 'redis://localhost:6379/0/cache', { expires_in: 10.minutes }
  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  #config.action_mailer.raise_delivery_errors = true
  #config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :smtp # :letter_opener
  config.action_mailer.smtp_settings = { host: "localhost", port: 1025 }
  config.action_mailer.default_url_options = { host: 'localhost:3000' }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log
  #config.active_support.deprecation = false

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  config.assets.compress = false

  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.middleware.insert_before Rails::Rack::Logger, DisableAssetsLogger

  config.log_redis = true
end
