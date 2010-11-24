module Lolita
  module Configuration
    class Columns 

      include Enumerable
      include ObservedArray
      
      attr_accessor :list
      attr_reader :dbi
      
      def initialize(list,dbi=nil)
        @list=list
        @dbi=dbi || list.dbi
        @columns=[]
      end
      
      def each
        @columns.each_with_index{|column,index|
          if column.is_a?(Lolita::Configuration::Column)
            yield column
          else
            raise "Any column must be Lolita::Configuratin::Column object instead of #{column.class}."
          end
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
          @columns<<build_element(&block)
        else
          @columns<<build_element(attributes)
        end
        self
      end

      private

      def collection_variable
        @columns
      end
      
      def build_element(column=nil,&block)
        if column.is_a?(Lolita::Configuration::Column)
          column
        elsif column.is_a?(Proc)
          Lolita::Configuration::Column.new(&column)
        elsif block_given?
          Lolita::Configuration::Column.new(&block)
        elsif [Symbol,String,Hash].include?(column.class)
          Lolita::Configuration::Column.new(column)
        else
          raise ArgumentError.new("Column can not be defined with #{column.class}.")
        end
      end

    end
  end
end
