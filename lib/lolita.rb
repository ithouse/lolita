main_time=Time.now

# Lolita directory path
LOLITA_ROOT=File.expand_path("#{__FILE__}/../..")
# Lolita load file path
LOLITA_LOAD_PATH=File.dirname(__FILE__)
# Lolita application path
LOLITA_APP_ROOT=File.join(File.expand_path("#{__FILE__}/../.."),"app")
$:<<LOLITA_LOAD_PATH unless $:.include?(LOLITA_LOAD_PATH)

require 'abstract' #FIXME remove from gem
require 'active_support/core_ext/numeric/time'
require 'active_support/callbacks'
require 'active_support/dependencies'
require 'lolita/errors'
# Require all ruby extensions
Dir["#{LOLITA_LOAD_PATH}/lolita/ruby_ext/**/*.*"].each do |path|
  require path
end

module Lolita
  autoload(:LazyLoader,'lolita/lazy_loader')
  autoload(:VERSION,'lolita/version')
  autoload(:ObservedArray,'lolita/observed_array')
  autoload(:Builder,'lolita/builder')
  #autoload(:Cells,'lolita/cells')
  module Adapter
    autoload :AbstractAdapter, 'lolita/adapter/abstract_adapter'
    autoload :ActiveRecord, 'lolita/adapter/active_record'
    autoload :Mongoid, 'lolita/adapter/mongoid'
  end

  module DBI
    autoload :Base, 'lolita/dbi/base'
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

    module FieldExtensions
      Dir["#{LOLITA_LOAD_PATH}/lolita/configuration/field_extensions/**/*.*"].each do |path|
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
  end

  MODULES=[]
  ROUTES={}
  CONTROLLERS={}
  
  def self.setup
    yield self
  end

  def self.root
    LOLITA_ROOT
  end

  def self.app_root
    LOLITA_APP_ROOT
  end
  #  @@before_load=[]
  #  def self.before_load &block
  #    @@before_load<< block if block_given?
  #    puts @@before_load.inspect
  #  end
  #
  #  @@after_load=[]
  #  def self.after_load *args
  #    @@after_load << block if block_given?
  #  end
  
  mattr_accessor :mappings
  @@mappings={}

  mattr_accessor :default_module
  @@default_module=nil

  def self.use(module_name)
    
  end

  mattr_accessor :user_classes
  @@user_classes=[]


  def self.add_mapping(resource,options={})
    mapping = Lolita::Mapping.new(resource, options)
    self.mappings[mapping.name] = mapping
    #self.default_scope ||= mapping.name
    mapping
  end

  def self.add_module name, options={}
    options.assert_valid_keys(:controller,:route,:model,:path)
    MODULES<<name.to_sym
    config={
      :route=>ROUTES,
      :controller=>CONTROLLERS
    }
    config.each{|key,value|
      next unless options[key]
      new_value=options[key]==true ? name : options[key]
      if value.is_a?(Hash)
        value[name]=new_value
      elsif !value.include?(new_value)
        value << new_value
      end
    }

    if options[:path]
      require File.join(options[:path],name.to_s)
    end
    #    if options[:model]
    #      model_path = (options[:model] == true ? "lolita/models/#{name}" : options[:model])
    #      Lolita::Models.send(:autoload, name.to_s.camelize.to_sym, model_path)
    #    end
  end
  
  if defined?(Rails)
 
    mattr_accessor :authentication
    @@authentication=nil
  end
end

require 'lolita/callbacks'
engine_time=Time.now

if defined?(Rails)
  require 'lolita/mapping'
  require 'lolita/rails'
  require 'lolita/modules'
end

puts "Lolita engine started in #{Time.at(Time.now-engine_time).strftime("%M:%S.%3N")}"
puts "Lolita started in #{Time.at(Time.now-main_time).strftime("%M:%S.%3N")}"