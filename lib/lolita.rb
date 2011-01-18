main_time=Time.now

LOLITA_ROOT=File.expand_path("#{__FILE__}/../..")
LOLITA_LOAD_PATH=File.dirname(__FILE__)
LOLITA_APP_ROOT=File.join(File.expand_path("#{__FILE__}/../.."),"app")
$:<<LOLITA_LODA_PATH unless $:.include?(LOLITA_LOAD_PATH)

require 'abstract'
require 'active_support/core_ext/numeric/time'
require 'active_support/dependencies'
#require 'lolita/rails_additions'
require 'lolita/errors'

#Dir.new("#{LOLITA_APP_ROOT}/cells/lolita").each do |f|
#  if f.to_s.match(/_cell\.rb$/)
#    require("#{LOLITA_APP_ROOT}/cells/lolita/#{f}")
#  end
#end

module Lolita
  autoload(:LazyLoader,'lolita/lazy_loader')
  autoload(:VERSION,'lolita/version')
  autoload(:ObservedArray,'lolita/observed_array')
  autoload(:Builder,'lolita/builder')
  autoload(:Cells,'lolita/cells')
  module Adapter
    autoload :AbstractAdapter, 'lolita/adapter/abstract_adapter'
    autoload :ActiveRecord, 'lolita/adapter/active_record'
    autoload :Mongoid, 'lolita/adapter/mongoid'
  end

  module DBI
    autoload :Base, 'lolita/dbi/base'
    autoload :RecordSet, 'lolita/dbi/record_set'
  end
  
  module Configuration
    autoload :Base, 'lolita/configuration/base'
    autoload :Column, 'lolita/configuration/column'
    autoload :Columns, 'lolita/configuration/columns'
    autoload :Field, 'lolita/configuration/field'
    autoload :FieldSet, 'lolita/configuration/field_set'
    autoload :List, 'lolita/configuration/list'
    autoload :Tab, 'lolita/configuration/tab'
    autoload :Tabs, 'lolita/configuration/tabs'
    
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
    autoload :FieldHelpers, 'lolita/controllers/field_helpers'
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
  
  mattr_accessor :mappings
  @@mappings={}

  mattr_accessor :default_module
  @@default_module=:rest

  mattr_accessor :user_classes
  @@user_classes=[]

  def self.add_user_class(user_class)
    if user_class.is_a?(Class)
      Lolita.user_classes<<user_class.to_s.underscore.gsub('/',"_").to_sym
    end
  end
  
  def self.add_mapping(resource,options={})
    mapping = Lolita::Mapping.new(resource, options)
    self.mappings[mapping.name] = mapping
    #self.default_scope ||= mapping.name
    mapping
  end

  def self.add_module name, options={}
    options.assert_valid_keys(:controller,:route,:model)
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

    if options[:model]
      model_path = (options[:model] == true ? "lolita/models/#{name}" : options[:model])
      Lolita::Models.send(:autoload, name.to_s.camelize.to_sym, model_path)
    end
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