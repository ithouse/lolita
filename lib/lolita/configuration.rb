module Lolita
   # All classes that want to use lolita for configuration should include this module.
  module Configuration
    # When Lolita::Configuration is included, it add hook for class <em>:after_lolita_loaded</em> and define class methods
    # <em>lolita</em> and <em>lolita=</em> and instance method <em>lolita</em> that refers to class method with same name.
    def self.included(base)
      base.class_eval do
        include Lolita::Hooks
        add_hook :after_lolita_loaded

        extend ClassMethods
        def lolita
          self.class.lolita
        end
      end
    end

    module ClassMethods
      # This is main method for configuration, it initialize new Lolita::Configuration::Core object, that have other methost to 
      # define different parts of configuration.
      def lolita(&block)
        Lolita::LazyLoader.lazy_load(self,:@lolita,Lolita::Configuration::Core,self,&block)
      end
      
      def lolita=(value)
        if value.is_a?(Lolita::Configuration::Core) || value.nil?
          @lolita = value
        else
          raise ArgumentError.new("Only Lolita::Configuration::Core is acceptable.")
        end
      end
    end
  end
end

require 'lolita/configuration/base'
require 'lolita/configuration/core'
require 'lolita/configuration/list'
require 'lolita/configuration/nested_list'
require 'lolita/configuration/tabs'
require 'lolita/configuration/tab'
require 'lolita/configuration/columns'
require 'lolita/configuration/column'
require 'lolita/configuration/fields'
require 'lolita/configuration/field'
require 'lolita/configuration/field_set'
require 'lolita/configuration/nested_form'
require 'lolita/configuration/search'
require 'lolita/configuration/filter'
require 'lolita/configuration/action'

require 'lolita/configuration/factory/field'
require 'lolita/configuration/factory/tab'

# Configuration for fields and tabs
["field","tab"].each do |type|
  Dir["#{File.dirname(__FILE__)}/configuration/#{type}/**/*.*"].each do |path|
    base_name=File.basename(path,".rb")
    require "lolita/configuration/#{type}/#{base_name}"
  end
end