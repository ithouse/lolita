require "lazy_loader"
require "rails_additions"
require "configuration/list"
require 'dbi/base'

module Lolita
  module Configuration

    def self.included(base)
      base.class_eval do
        extend ClassMethods
        def lolita # tikai getteris
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

    class Base

      attr_reader :dbi
    
      def initialize(parent_class,&block)
        if parent_class.is_a?(Class)
          puts "Lolita initialized for #{parent_class}"
          @dbi=Lolita::DBI::Base.new(parent_class)
        else
          raise ArgumentError.new("Parent class must be Class object instead of #{parent_class.class}")
        end
        block_given? ? self.instance_eval(&block) : self.generate!
      end
      
      def list &block
        Lolita::LazyLoader.lazy_load(self,:@list,List,@dbi,&block)
      end

      def generate!
        self.list
      end
      
    end
  end
end

