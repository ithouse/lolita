require "lolita/config.rb"
$lolita_config = Lolita::Config.new

require "lolita/authorization.rb"

ActionController::Base.send :include, Lolita::Authorization
ActionView::Base.send :include, Lolita::Authorization