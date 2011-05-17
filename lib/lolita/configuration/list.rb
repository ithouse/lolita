module Lolita
  module Configuration
    class List
      include Lolita::Builder
       
      attr_reader :dbi,:initialized_attributes
      
      def initialize(*args,&block)
        if args && args[0].is_a?(Lolita::DBI::Base)
          @dbi=args.shift
        end
        @columns=Lolita::Configuration::Columns.new(self)
        @set_attributes=[]
        set_attributes(*args)
        self.instance_eval(&block) if block_given?
        self.generate!()
      end

      # Look for methods in Page class. Load @page on demand and call method on it.
      def method_missing(method_name,*args,&block)
        if Lolita::Configuration::Page.public_instance_methods.include?(method_name.to_sym)
          @page||=Lolita::Configuration::Page.new(@dbi)
          @page.send(method_name.to_sym,*args,&block)
        else
          super
        end
      end
      # Set columns. Allowed classes are Lolita::Configuration::Columns or
      # Array.
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

      # Get list columns (also block setter)
      def columns(*args)
        if args && !args.empty?
          self.columns=args
        end
        self.generate!
        @columns
      end

      # Generate uninitialized attributes
      def generate!()
        @columns.generate! unless is_set?(:columns)
      end

      # checks if filter defined
      def filter?
        @filter.is_a?(Lolita::Configuration::Filter)
      end

      # Filter by now works only for these field types:
      # - belongs_to
      # - boolean
      #
      def filter(*args,&block)
        @filter ||= Lolita::Configuration::Filter.new(self.dbi,*args,&block)
      end
      
      # Block setter for columns
      def column(*args,&block)
        set_attribute(:columns)
        if block_given?
          @columns<<block
        else
          @columns.add(Lolita::Configuration::Column.new(@dbi,*args))
        end
      end

      private

      # Used to set attributes if block not given.
      def set_attributes(*args)
        if args && args[0]
          if args[0].is_a?(Hash)
            args[0].each{|m,value|
              self.send("#{m}=".to_sym,value)
            }
          else
            raise ArgumentError.new("Lolita::Configuration::List arguments must be Hash instead of #{args[0].class}")
          end
        end
      end
      
      # Mark attribute as set.
      def set_attribute(var)
        @set_attributes<<var unless is_set?(var)
      end

      # Determine if attribute is set and don't need to generate it.
      def is_set?(var)
        @set_attributes.include?(var)
      end

    end
  end
end