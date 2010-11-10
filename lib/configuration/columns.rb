require 'dbi/base'
require 'configuration/column'

module Lolita
  module Configuration
    class Columns 

      include Enumerable
      
      attr_accessor :list
      attr_reader :dbi
      
      def initialize(list,dbi=nil)
        @list=list
        @dbi=dbi || list.dbi
        @columns=[]
      end

      def method_missing(method,*args,&block)
        if @columns.detect{|column| !column.is_a?(Lolita::Configuration::Column)}
          initialize_all_columns
        end
        @columns.__send__(method,*args,&block)
      end
      
      def each
        @columns.each_with_index{|column,index|
          unless column.is_a?(Lolita::Configuration::Column)
            @columns[index]=set_real_column(column)
          end
          yield @columns[index]
        }
      end

      def generate!
        @columns.clear
        @dbi.fields.each_with_index{|field,index|
          @columns[index]=Lolita::Configuration::Column.new(field)
        }
      end

      def add attributes={},&block
        if block_given?
          @columns<<set_real_column(&block)
        else
          @columns<<set_real_column(attributes)
        end
      end
      private

      def initialize_all_columns
        @columns.collect!{|column| set_real_column(column) unless column.is_a?(Lolita::Configuration::Column)}
      end

      def set_real_column(column=nil,&block)
        if column.is_a?(Proc)
          Lolita::Configuration::Column.new(&column)
        elsif block_given?
          Lolita::Configuration::Column.new(&block)
        elsif column
          Lolita::Configuration::Column.new(column)
        else
          raise ArgumentError.new("Must give Proc or Hash or block.")
        end
      end

    end
  end
end
