module Lolita
  module Configuration
    class Columns

      include Enumerable
      include ObservedArray
      include Lolita::Builder

      attr_reader :dbi
      
      def initialize(dbi, *args, &block)
        @dbi=dbi
        @columns=[]
        @generated_yet = (block_given? || (args && args.any?))
        set_attributes(*args)
        self.instance_eval(&block) if block_given?
      end

      # Add column to columns Array. Receive attributes for column as Hash and/or block.
      def column *args, &block
        @columns << build_element(*args,&block)
        @columns.last
      end

      # Find first column by name
      def by_name(name)
        name = name.to_sym
        self.detect do |column|
          column.name == name
        end
      end
      
      def each
        self.populate
        @columns.each_with_index{|column,index|
          if column.is_a?(Lolita::Configuration::Column)
            yield column
          else
            raise "Any column must be Lolita::Configuratin::Column object instead of #{column.class}."
          end
        }
      end


      def generate!
        @generated_yet = true
        @columns.clear
        @dbi.fields.each_with_index{|field,index|
          unless field.technical?
            @columns << Lolita::Configuration::Column.new(@dbi,field)
          end
        }
      end

      def populate
        self.generate! if @columns.empty? && !@generated_yet
      end

      private

      def set_attributes(*args)
        if args && args.any?
          options = args.extract_options! || {}
          args.each do |col_name|
            column col_name
          end
          options.each do |key,value|
            if key == :column
              column value
            end
          end
        end
      end

      def generate_collection_elements!
        self.populate
      end

      def collection_variable
        @columns
      end
      
      def build_element(*column,&block)
        if column[0].is_a?(Lolita::Configuration::Column)
          column[0]
        elsif column[0].is_a?(Proc)
          Lolita::Configuration::Column.new(@dbi,&column[0]) 
        else
          Lolita::Configuration::Column.new(@dbi,*column, &block)
        end
      end

    end
  end
end
