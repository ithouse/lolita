require 'lolita/rails/routes'


ActiveSupport.on_load(:action_controller) {
	include Lolita::Controllers::ViewUserHelpers
	include Lolita::Controllers::UrlHelpers
	include Lolita::Controllers::ComponentHelpers
}
ActiveSupport.on_load(:action_view) {
	include Lolita::Controllers::ViewUserHelpers
	include Lolita::Controllers::UrlHelpers
	include Lolita::Controllers::ComponentHelpers
}

module Lolita
	class Engine < Rails::Engine
		config.lolita=Lolita
	  config.i18n.load_path += Dir[File.join(Lolita.root,'config', 'locales','default', '*.{yml}')]
	end
end
