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
          self.class.lolita_config
        end
      end
    end

    module ClassMethods
      def lolita(&block)
        Lolita::LazyLoader.lazy_load(self,:@lolita,Lolita::Configuration::Base,self,&block)
      end
    end

    class Base

      attr_reader :dbi
    
      def initialize(*args,&block)
        puts "Lolita initialized for #{args[0]}"
        @dbi=Lolita::DBI::Base.new(args[0])
        block_given? ? self.instance_eval(&block) : self.generate
      end
      
      def list &block
        Lolita::LazyLoader.lazy_load(self,:@list,List,@dbi,&block)
      end

      def set_collection(value=nil)
        @collection=if value
          value
        else
          DBI::Base.collection_name
        end
      end

      def collection()
        @collection
      end

      def generate
        self.list
        self.collection
      end
      
    end
  end
end

