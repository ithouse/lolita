$lolita_config = Lolita::Config.new
Globalize::Locale.set_base_language Lolita.config.i18n :language_code
ActionController::Dispatcher.middleware.insert_before(ActionController::Base.session_store, FlashSessionCookieMiddleware, ActionController::Base.session_options[:key])