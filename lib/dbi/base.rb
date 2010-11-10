require 'dbi/abstract_interface'
require 'dbi/column_generator'
require 'dbi/record_set'

Dir[File.expand_path(File.join(File.dirname(__FILE__),'..','connector','**','*.rb'))].each {|f| require f}

module Lolita
  module DBI
    class Base

      attr_reader :collection,:source, :klass
      def initialize(class_object)
        if class_object.respond_to?(:collection)
          @source=:mongo
          @collection=class_object.collection
        elsif class_object.respond_to?(:table_name)
          @source=:mysql
          @collection=class_object.table_name
        else
          raise ArgumentError.new("DBI::Base can work only with classes that include Mongoid::Document or extend ActiveRecord::Base instead of #{class_object.class}")
        end
        @klass=class_object
      end
    end
  end
end
