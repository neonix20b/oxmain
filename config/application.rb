require File.expand_path('../boot', __FILE__)
require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
#RAILS_GEM_VERSION = '2.3.10' unless defined? RAILS_GEM_VERSION
@per_page=10
Bundler.require(:default, Rails.env) if defined?(Bundler)
module Oxmain
  class Application < Rails::Application
  config.time_zone = 'UTC'
  config.i18n.default_locale = :ru
  config.session_store :active_record_store
	config.encoding = "utf-8"
	config.filter_parameters += [:password]
	config.active_support.deprecation = :notify
  end
end

