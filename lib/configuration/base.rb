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

