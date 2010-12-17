
LOLITA_ROOT=File.dirname(__FILE__)
$:<<LOLITA_ROOT unless $:.include?(LOLITA_ROOT)

require 'abstract'
require 'active_support/core_ext/numeric/time'
require 'active_support/dependencies'
#require 'lolita/rails_additions'
require 'lolita/errors'

module Lolita
  autoload(:LazyLoader,'lolita/lazy_loader')
  autoload(:VERSION,'lolita/version')
  autoload(:ObservedArray,'lolita/observed_array')
  autoload(:Builder,'lolita/builder')
  
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

if defined?(Rails)
  require 'lolita/mapping'
  require 'lolita/rails'
  require 'lolita/modules'
end


