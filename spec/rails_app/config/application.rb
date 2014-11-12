require File.expand_path('../boot', __FILE__)
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"

Bundler.require(:default, LOLITA_ORM, Rails.env) if defined?(Bundler)

module RailsApp
	class Application < Rails::Application
		# Add additional load paths for your own custom dirs
		config.root = File.expand_path('../..',__FILE__)
		config.active_support.deprecation=:log
		config.before_initialize do
      Dir[File.expand_path("../../app/orm/#{LOLITA_ORM}/*.rb", __FILE__)].map do |model|
        require model
      end
    end

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
