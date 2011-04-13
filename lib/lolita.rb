
$:<<File.dirname(__FILE__) unless $:.include?(File.dirname(__FILE__))
LOLITA_VERSION=File.read(File.expand_path("../../VERSION",__FILE__)).gsub(/[^.\w]/,"")
puts "=> Lolita #{LOLITA_VERSION} starting#{defined?(Rails) ? " with Rails" : ""}"

# TODO should allow run lolita seperated
unless (["-d","--debug"] & ARGV).empty?
  require "ruby-debug"
  Debugger.settings[:autoeval]=true
else
  unless self.respond_to?(:debugger)
    def debugger
      warn "Debugger called at #{caller.first} was ignored, run lolita with -d to attatch debugger."
    end
  end
end

require 'abstract'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_time/conversions'
require 'active_support/concern'
require 'active_support/callbacks'
require 'active_support/dependencies'
require 'lolita/errors'
# Require all ruby extensions
Dir["#{File.dirname(__FILE__)}/lolita/ruby_ext/**/*.*"].each do |path|
  require path
end

module Lolita
  autoload(:LazyLoader,'lolita/lazy_loader')
  autoload(:VERSION,'lolita/version')
  autoload(:ObservedArray,'lolita/observed_array')
  autoload(:Builder,'lolita/builder')
  autoload(:BaseConfiguration,'lolita/base_configuration')

  module Adapter
    autoload :AbstractAdapter, 'lolita/adapter/abstract_adapter'
    autoload :ActiveRecord, 'lolita/adapter/active_record'
    autoload :Mongoid, 'lolita/adapter/mongoid'
  end

  module DBI
    autoload :Base, 'lolita/dbi/base'
  end
  
  autoload :Hooks, "lolita/hooks"
  module Hooks
    autoload :NamedHook, "lolita/hooks/named_hook"
  end
 

  module Configuration
    autoload :Factory, 'lolita/configuration/factory'
    autoload :Base, 'lolita/configuration/base'
    autoload :Column, 'lolita/configuration/column'
    autoload :Columns, 'lolita/configuration/columns'
    autoload :Fields, 'lolita/configuration/fields'
    autoload :FieldSet, 'lolita/configuration/field_set'
    autoload :List, 'lolita/configuration/list'
    autoload :Page, 'lolita/configuration/page'
    autoload :Tabs, 'lolita/configuration/tabs'
    autoload :Filter, 'lolita/configuration/filter'

    module Field
      extend Lolita::Configuration::Factory
      autoload :Base, 'lolita/configuration/field'
       ["field"].each do |type|
        Dir["#{File.dirname(__FILE__)}/lolita/configuration/#{type}/**/*.*"].each do |path|
          base_name=File.basename(path,".rb")
          autoload :"#{base_name.camelize}", "lolita/configuration/#{type}/#{base_name}"
        end
      end
    end
    
    module Tab
      extend Lolita::Configuration::Factory
      autoload :Base, 'lolita/configuration/tab'
      ["tab"].each do |type|
        Dir["#{File.dirname(__FILE__)}/lolita/configuration/#{type}/**/*.*"].each do |path|
          base_name=File.basename(path,".rb")
          autoload :"#{base_name.camelize}", "lolita/configuration/#{type}/#{base_name}"
        end
      end
    end
    
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        def lolita
          self.class.lolita
        end
      end
    end

    module ClassMethods
      def lolita(&block)
        Lolita::LazyLoader.lazy_load(self,:@lolita,Lolita::Configuration::Base,self,&block)
      end
      def lolita=(value)
        if value.is_a?(Lolita::Configuration::Base)
          @lolita=value
        else
          raise ArgumentError.new("Only Lolita::Configuration::Base is acceptable.")
        end
      end
    end
  end

  module Test
    autoload :Matchers, 'lolita/test/matchers'
  end
  
  module Controllers
    autoload :InternalHelpers, 'lolita/controllers/internal_helpers'
    autoload :UserHelpers, 'lolita/controllers/user_helpers'
    autoload :UrlHelpers, 'lolita/controllers/url_helpers'
    autoload :ComponentHelpers, 'lolita/controllers/component_helpers'
    autoload :ViewUserHelpers, 'lolita/controllers/view_user_helpers'
  end

  module Navigation
    autoload :Tree, "lolita/navigation/tree"
    autoload :Branch, "lolita/navigation/branch"
  end

  @@scopes={}

  def self.scope name=nil
    name||=scope_name
    @@scopes[name]||=Lolita::BaseConfiguration.new(name)
    @@scopes[name]
  end

  def self.setup
    yield scope
  end

  def self.scope_name
    :default
  end
  
  def self.root
    @@root||=File.expand_path("#{__FILE__}/../..")
  end

  def self.app_root
    @@app_root||=File.join(File.expand_path("#{__FILE__}/../.."),"app")
  end
  
  def self.method_missing method_name, *args, &block
    scope.send(method_name,*args,&block)
  end

  module Generators
    autoload :FileHelper, File.join(Lolita.root,"lib","generators","helpers","file_helper")
  end
  
end

if defined?(Rails)
  require 'lolita/rails/all'
end
