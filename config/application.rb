require File.expand_path('../boot', __FILE__)

# disable ActiveRecord by requiring these 5 and commenting rails/all
# require "action_controller/railtie"
# require "action_mailer/railtie"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module JukinRipper
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    # soft-code customizations
    config = YAML.load(File.read(File.expand_path('../application.yml', __FILE__)))
    config.merge! config.fetch(Rails.env, {})
    config.each do |key, value|
      ENV[key] = value unless value.kind_of? Hash
    end
  end
end
