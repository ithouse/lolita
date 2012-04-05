require File.expand_path('../boot', __FILE__)
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "rails/test_unit/railtie"
require "sprockets/railtie"

Bundler.require(:default, LOLITA_ORM, Rails.env) if defined?(Bundler)

module RailsApp
	class Application < Rails::Application
		# Add additional load paths for your own custom dirs
		config.root = File.expand_path('../..',__FILE__)
		config.active_support.deprecation=:log
		#config.autoload_paths.reject!{ |p| p =~ /\/app\/(\w+)$/ && !%w(controllers helpers views).include?($1) }
		config.autoload_paths += [ "#{config.root}/app/#{LOLITA_ORM}" ]

		# Configure sensitive parameters which will be filtered from the log file.
		config.filter_parameters << :password

		config.action_mailer.default_url_options = { :host => "localhost:3000" }
		 config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
	end
end
