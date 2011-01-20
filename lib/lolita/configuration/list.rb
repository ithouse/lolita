module Lolita
  module Configuration
    class List
      include Lolita::Builder
       
      attr_reader :dbi,:initialized_attributes
      attr_writer :per_page
      
      def initialize(*args,&block)
        if args && args[0].is_a?(Lolita::DBI::Base)
          @dbi=args.shift
        end
        @columns=Lolita::Configuration::Columns.new(self)
        @sort_columns=[]
        @set_attributes=[]
        set_attributes(*args)
        self.instance_eval(&block) if block_given?
        self.generate!()
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

      # Records per page (also block setter)
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

      # Paginate
      # Options:
      # * <tt>:per_page</tt> - Records per page, if not given use list default per page.
      # * <tt>:page</tt> - Comment to get
      # * <tt>page</tt> - Comment to get
      # ====Example
      #     list.paginate(1)
      #     list.paginate
      #     lsit.paginate(:per_page=>2,:page=>1)
      def paginate *args
        options=args ? args.extract_options! : {}
        options[:page]||=((args && args.first) || 1)
        options[:per_page]||=@per_page || 10
        @page=@dbi.paginate(options)#Lolita::DBI::RecordSet.new(@dbi,options)
      end

      # Return last page created by paginate.
      def page
        @page
      end

      # Generate uninitialized attributes
      def generate!()
        @columns.generate! unless is_set?(:columns)
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

      # Block setter for columns
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