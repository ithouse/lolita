require 'find'

# load patches
Find.find(File.join(File.dirname(__FILE__), "patch")) do |path|
  require(path) if path =~ /\.rb$/
end

ActionView::Base.send :include, BaseHelper
#ActionController::Base.send :include, Lolita::Authorization
#ActionView::Base.send :include, Lolita::Authorization

# Include TranslationHelper into all Lolitas helpers
Dir.glob(File.join(File.dirname(__FILE__),'app','helpers','*_helper.rb')) do |path|
  unless File.basename(path) == 'application_helper.rb'
    nspace = path.split("/")[-2]
    nspace = %w(admin cms extensions).include? nspace ? nspace : nil
    eval "#{(nspace ? "#{nspace}::#{File.basename(path).split(".")[0]}" : "#{File.basename(path).split(".")[0]}").camelcase}.send :include, Extensions::TranslationHelper"
  end
end

require "#{File.join(File.dirname(__FILE__))}/lib/load_lolita_core.rb"

# load factories
Dir.glob("#{File.join(File.dirname(__FILE__))}/spec/factories/*/*.rb").each do |path|
  require path
end if RAILS_ENV == "test"

require 'rake'
# load rake tasks for plugins
Dir.glob("#{RAILS_ROOT}/vendor/plugins/lolita/plugins/**/tasks/*.rake").each do |rake_file|
  Rake.application.add_import rake_file
end
