$lolita_config = Lolita::Config.new
Globalize::Locale.set_base_language(Lolita.config.i18n(:language_code))
ActionController::Dispatcher.middleware.insert_before(ActionController::Base.session_store, FlashSessionCookieMiddleware, ActionController::Base.session_options[:key])
ActionMailer::Base.default_url_options[:host] = Lolita.config.system :domain
if Lolita.config.email :smtp_settings
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = Lolita.config.email :smtp_settings
end
