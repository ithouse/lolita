require 'lolita/rails/routes'
#ActiveSupport.on_load(:action_controller) { include Lolita::Controllers::UrlHelpers }
#ActiveSupport.on_load(:action_view) { include Lolita::Controllers::UrlHelpers }

module Lolita
  class Engine < Rails::Engine
    config.lolita=Lolita
    #paths["app/models"]="app/models/#{Lolita.orm}"
    config.asset_path = "/lolita/%s"
    config.serve_static_assets = true
  end
end