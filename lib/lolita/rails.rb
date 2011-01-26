require 'lolita/rails/routes'
ActiveSupport.on_load(:action_controller) {
  include Lolita::Controllers::UrlHelpers
  include Lolita::Controllers::ComponentHelpers
}
ActiveSupport.on_load(:action_view) {
  include Lolita::Controllers::UrlHelpers
  include Lolita::Controllers::ComponentHelpers
}
Dir["#{LOLITA_APP_ROOT}/helpers/components/**/*.*"].each do |f|
  puts f
end
module Lolita
  class Engine < Rails::Engine
    config.lolita=Lolita
   puts config.paths["app"]
    #config.asset_path = "/lolita/%s"
    # config.serve_static_assets = true
  end
end