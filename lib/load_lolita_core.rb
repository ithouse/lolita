$lolita_config = Lolita::Config.new
#Load kernel
ActionController::Base.send :include, Lolita::ControllerKernel
#Load authorization
ActionController::Base.send :include, Lolita::Authorization
ActionView::Base.send :include, Lolita::Authorization
#Load multimedia
ActionController::Base.send :include, Lolita::Multimedia
#Load translations
ActionController::Base.send :include, Lolita::Translation
#Load utilities
ActionController::Base.send :include, Lolita::ControllerUtilities
#Load routes hack
ActionController::Routing::RouteSet.send :include, Lolita::RouteHack

