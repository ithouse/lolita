require 'find'

## add all maps to path
#%w{
#  middleware app/models app/helpers app/controllers
#  app/models/extensions app/helpers/extensions app/controllers/extensions
#  app/models/extensions/cms app/helpers/extensions/cms app/controllers/extensions/cms
#}.each do |dir|
#  path = File.join(File.dirname(__FILE__), dir)
#  $LOAD_PATH << path
#  ActiveSupport::Dependencies.load_paths << path
#  ActiveSupport::Dependencies.load_once_paths.delete(path) unless RAILS_ENV == 'production'
#end

# load patches
Find.find(File.join(File.dirname(__FILE__), "patch")) do |path|
  require(path) if path =~ /\.rb$/
end

# extend ActionController with our extensions
ActionController::Base.send :include, AuthenticatedSystem
ActionController::Base.send :include, Extensions::FileAndPictureManager
ActionController::Base.send :include, Extensions::PermissionControll
ActionController::Base.send :include, Extensions::Paging
ActionController::Base.send :include, Extensions::Translation
ActionController::Base.send :include, Extensions::Util
ActionController::Base.send :include, Extensions::AdvancedFilterExtension

ActionView::Base.send :include, BaseHelper

# Include TranslationHelper into all Lolitas helpers
#Dir.glob(File.join(File.dirname(__FILE__),'app','helpers','*_helper.rb')) do |path|
#  unless File.basename(path) == 'base_helper.rb'
#    nspace = path.split("/")[-2]
#    nspace = %w(admin cms extensions).include? nspace ? nspace : nil
#    eval "#{(nspace ? "#{nspace}::#{File.basename(path).split(".")[0]}" : "#{File.basename(path).split(".")[0]}").camelcase}.send :include, Extensions::TranslationHelper"
#  end
#end

# add lolita's template path
ActionController::Base.view_paths = ActionController::Base.view_paths.dup.unshift("#{RAILS_ROOT}/vendor/plugins/lolita/lib/app/views")

# Load flash session middleware
ActionController::Dispatcher.middleware.insert_before(ActionController::Base.session_store, FlashSessionCookieMiddleware, ActionController::Base.session_options[:key])
