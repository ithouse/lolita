require "configuration/column"
require "configuration/columns"
require 'rails_additions'
require 'dbi/base'

module Lolita
  module Configuration
    class List

      attr_reader :dbi,:initialized_attributes
      attr_writer :per_page
      
      def initialize(*args,&block)
        if args && args[0].is_a?(Lolita::DBI::Base)
          @dbi=args.shift
        end
        @columns=Lolita::Configuration::Columns.new(self)
        @sort_columns=[]
        @set_attributes=[]
        block_given? ? self.instance_eval(&block) : self.set_attributes(*args)
        self.generate()
      end

      def columns=(value)
        set_attribute(:columns)
        if value.is_a?(Lolita::Configuration::Columns)
          @columns=value
        elsif value.is_a?(Array)
          value.each{|el| @columns<<el}
        else
          raise ArgumentError.new("Columns must bet Array or Lolita::Configuration::Columns.")
        end
      end
      
      def columns(value=nil)
        if value
          self.columns=value
        end
        unless is_set?(:columns)
          @columns.generate!
        end
        @columns
      end

      def per_page(value=nil)
        @per_page=value if value
        @per_page
      end

      def asc(column)
        @sort_columns<<[column.to_sym,:asc]
        self
      end

      def desc(column)
        @sort_columns<<[column.to_sym,:desc]
        self
      end

      def sort_columns
        @sort_columns
      end
      
      def paginate *args
        options=args.extract_options!
        options[:page]||=args.first || 1
        options[:per_page]||=@per_page
        Lolita::LazyLoader.lazy_load(self,:@record_set,Lolita::DBI::RecordSet,@dbi,options)
      end
      
      def generate()
        @columns.generate! unless is_set?(:columns)
      end

      def set_attributes(*args)
        if args && args[0]
          if args[0].is_a?(Hash)
            args[0].each{|m,value|
              puts "method #{m}="
              self.send("#{m}=".to_sym,value)
            }
          else
            raise ArgumentError.new("Lolita::Configuration::List arguments must be Hash instead of #{args[0].class}")
          end
        end
      end
      private

      # Mark attribute as set.
      def set_attribute(var)
        @set_attributes<<var unless is_set?(var)
      end

      # Determine if attribute is set and don't need to generate it.
      def is_set?(var)
        @set_attributes.include?(var)
      end
      
      def column(*args,&block)
        set_attribute(:columns)
        if block_given?
          @columns<<block
        else
          @columns<<args[0]
        end
      end
    
    end
  end
end