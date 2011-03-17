main_time=Time.now

$:<<File.dirname(__FILE__) unless $:.include?(File.dirname(__FILE__))

require 'abstract' #FIXME remove from gem
require 'active_support/core_ext/numeric/time'
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
  
  module Hooks
    require 'lolita/hooks/hooks'
    include Lolita::Hooks::Hooks
    autoload :Base, 'lolita/hooks/base'
    autoload :Component, 'lolita/hooks/component'
  end

  module Configuration
    autoload :Base, 'lolita/configuration/base'
    autoload :Column, 'lolita/configuration/column'
    autoload :Columns, 'lolita/configuration/columns'
    autoload :Field, 'lolita/configuration/field'
    autoload :FieldSet, 'lolita/configuration/field_set'
    autoload :List, 'lolita/configuration/list'
    autoload :Page, 'lolita/configuration/page'
    autoload :Tab, 'lolita/configuration/tab'
    autoload :Tabs, 'lolita/configuration/tabs'

     Dir["#{File.dirname(__FILE__)}/lolita/configuration/tab/**/*.*"].each do |path|
        base_name=File.basename(path,".rb")
        autoload :"#{base_name.capitalize}Tab", "lolita/configuration/tab/#{base_name}"
     end

    module FieldExtensions
      Dir["#{File.dirname(__FILE__)}/lolita/configuration/field_extensions/**/*.*"].each do |path|
        base_name=File.basename(path,".rb")
        autoload base_name.capitalize.to_sym, "lolita/configuration/field_extensions/#{base_name}"
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

  module Controllers
    autoload :InternalHelpers, 'lolita/controllers/internal_helpers'
    autoload :UserHelpers, 'lolita/controllers/user_helpers'
    autoload :UrlHelpers, 'lolita/controllers/url_helpers'
    autoload :ComponentHelpers, 'lolita/controllers/component_helpers'
    autoload :ViewUserHelpers, 'lolita/controllers/view_user_helpers'
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
  
end

engine_time=Time.now

if defined?(Rails)
  require 'lolita/mapping'
  require 'lolita/rails'
  require 'lolita/modules'
end

puts "Lolita engine started in #{Time.at(Time.now-engine_time).strftime("%M:%S.%3N")}"
puts "Lolita started in #{Time.at(Time.now-main_time).strftime("%M:%S.%3N")}"