require 'dbi/record_set'

Dir[File.expand_path(File.join(File.dirname(__FILE__),'..','adapter','**','*.rb'))].each {|f| require f}

module Lolita
  module DBI
    class Base

      attr_reader :collection,:adapter, :klass
      def initialize(class_object)
        @klass=class_object
        detect_adapter
        connect_adapter
      end

      def dbi
        self
      end
      
      def detect_adapter
        if defined?(Mongoid) && defined?(Mongoid::Document) && self.klass.ancestors.include?(Mongoid::Document)
          @adapter=:mongoid
          @collection=self.klass.collection
        elsif defined?(ActiveRecord) && defined?(ActiveRecord::Base) && self.klass.ancestors.include?(ActiveRecord::Base)
          @adapter=:active_record
          @collection=self.klass.table_name
        else
          raise ArgumentError.new("DBI::Base can work only with classes that include Mongoid::Document or extend ActiveRecord::Base instead of #{class_object.class}")
        end
      end

      def connect_adapter()
        adapter_name=@adapter
        self.class.class_eval do
          include "Lolita::Adapter::#{adapter_name.to_s.camelize}".constantize
        end
      end
    end
  end
end
