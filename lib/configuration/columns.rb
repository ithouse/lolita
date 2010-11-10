require 'dbi/base'
require 'configuration/column'

module Lolita
  module Configuration
    class Columns < Array

      attr_accessor :list
      def initialize(list)
        @list=list
        super(0)
      end

      def each
        self.each{|column|
          unless column.is_a?(::Column)
            column=set_real_column(column)
          end
          yield column
        }
      end

      def [](index)
        unless super(index).is_a?(::Column)
          self[index]=set_real_column(index)
        end
        super(index)
      end

      def first
        self[0]
      end

      def last
        self[self.size-1]
      end

      def generate!
        self.clear
        generator=DBI::ColumnGenerator.new(@list.dbi)
        generator.fields.each_with_index{|field,index|
          self[index]=Lolita::Configuration::Column.new(field)
        }
      end

      private

      def set_real_column(column)
        if column.is_a?(Proc)
          Lolita::Configuration::Column.new(column)
        else
          Lolita::Configuration::Column.new(&column)
        end
      end
      # TODO pielikt klāt lai ielādē reālu kolonnu ja prasa [] vai first, last
    end
  end
end
