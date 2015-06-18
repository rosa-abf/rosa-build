require File.expand_path('../boot', __FILE__)

require 'rails/all'
require './lib/api_defender'

# Prevent deprecation warning
I18n.config.enforce_available_locales = true

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Rosa
  class Application < Rails::Application
    config.i18n.enforce_available_locales = true

    unless Rails.env.test?
      require 'close_ar_connections_middleware'
      config.middleware.insert_after('Rack::Sendfile', CloseArConnectionsMiddleware)
    end

    # Rate limit
    config.middleware.insert_before Rack::Runtime, ApiDefender
    # Rack::UTF8Sanitizer is a Rack middleware which cleans up invalid UTF8 characters in request URI and headers.
    config.middleware.insert 0, Rack::UTF8Sanitizer

    config.autoload_paths += %W(#{config.root}/lib)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/app/presenters)
    config.autoload_paths += %W(#{config.root}/app/jobs)
    config.autoload_paths += %W(#{config.root}/app/jobs/concerns)
    config.autoload_paths += %W(#{config.root}/app/services/abf_worker)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Enable the asset pipeline
    config.assets.enabled                  = true
    config.assets.initialize_on_precompile = false # http://bit.ly/u7pQKz
    config.assets.precompile              += %w(active_admin.js active_admin.css)

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.log_redis = false

    config.angular_templates.ignore_prefix = 'angularjs/templates/'
  end
end
