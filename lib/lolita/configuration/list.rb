module Lolita
  module Configuration
    class List
      include Lolita::Builder
       
      attr_reader :dbi,:initialized_attributes
      lolita_accessor :per, :pagination_method
      
      def initialize(*args,&block)
        if args && args[0].class.to_s.match(/Lolita::Adapter/) || args[0].is_a?(Lolita::DBI::Base)
          @dbi=args.shift
        end
        @columns=Lolita::Configuration::Columns.new(self)
        @set_attributes=[]
        set_attributes(*args)
        self.instance_eval(&block) if block_given?
        self.generate!()
        set_default_attributes
      end

      # For details see Lolita::Configuration::Search
      def search *args, &block
        if (args && args.any?) || block_given?
          @search = Lolita::Configuration::Search.new(self.dbi,*args,&block)
        end
        @search
      end

      # Define or return pagination method. This method is used by DBI adapters to delegate domain specific
      # pagination back to model.
      # ====Example
      #   list do 
      #     pagination_method :paginate_with_profiles
      #   end
      def pagination_method(value = nil)
        if value
          self.pagination_method = value
        end
        @pagination_method
      end

      def pagination_method=(value)
        @pagination_method = value
      end

      # Return page for list display. Method requires two arguments:
      # * <tt>current_page</tt> - number of current page
      # * <tt>request (optional) </tt> - request that is passed to adapter that passes this to model when #pagination_method is defined
      def paginate(current_page, request = nil)
        page_criteria = dbi.paginate(current_page,@per,:request => request, :pagination_method => @pagination_method)
        if self.search
          page_criteria = page_criteria.merge(self.search.run(request.params[:q],request))
        end
        page_criteria
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

      def set_default_attributes
        @per ||= 10
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