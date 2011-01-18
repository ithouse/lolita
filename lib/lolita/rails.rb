require 'lolita/rails/routes'
#ActiveSupport.on_load(:action_controller) { include Lolita::Controllers::UrlHelpers }
#ActiveSupport.on_load(:action_view) { include Lolita::Controllers::UrlHelpers }
Lolita.orm||=if defined?(ActiveRecord)
  :active_record
elsif defined?(Mongoid)
  :mongoid
end

module Lolita
  class Engine < Rails::Engine
    config.lolita=Lolita
    puts config.app_generators.orm
    #paths["app/models"]="app/models/#{Lolita.orm}"
    #config.asset_path = "/lolita/%s"
    config.serve_static_assets = true
  end
end