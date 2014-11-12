require 'lolita/controllers'

ActiveSupport.on_load(:action_controller) {
  include Lolita::Controllers::UrlHelpers
  include Lolita::Controllers::ComponentHelpers
  include Lolita::Extensions
}
ActiveSupport.on_load(:action_view) {
  include Lolita::Controllers::ComponentHelpers
  include Lolita::Controllers::RailsHelpers
  include Lolita::Extensions
}

module ActionView
  module RoutingUrlFor
    include Lolita::Controllers::UrlHelpers
  end
end

module Lolita
  class Engine < Rails::Engine
    config.lolita = Lolita
    config.i18n.load_path += Dir[File.join(Lolita.root,'config', 'locales','default', '*.{yml}')]
    config.before_initialize do
      Haml.init_rails(binding)
      Haml::Template.options[:format] = :html5
    end
  end
end
