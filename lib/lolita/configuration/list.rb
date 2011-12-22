module Lolita
  module Configuration
    class List
      include Lolita::Builder
       
      attr_reader :dbi,:initialized_attributes
      attr_accessor :parent

      lolita_accessor :per, :pagination_method
      
      def initialize(*args,&block)
        if args && args[0].class.to_s.match(/Lolita::Adapter/) || args[0].is_a?(Lolita::DBI::Base)
          @dbi = args.shift
        end 
        set_attributes(*args)
        self.instance_eval(&block) if block_given?
        set_default_attributes
      end

      def list(*args, &block)
        if args && args.any? || block_given?
          association_name = args[0]
          if args[0].to_s.match(/Lolita::Adapter/)
            association_dbi = args[0]
          else
            association = dbi.associations[association_name.to_s.to_sym]
            association_dbi = association && Lolita::DBI::Base.create(association.klass)
          end
          raise Lolita::UnknownDBIError.new("No DBI specified for list sublist") unless association_dbi
          Lolita::LazyLoader.lazy_load(self,:@list,Lolita::Configuration::List,association_dbi,&block)
        else
          Lolita::LazyLoader.lazy_load(self,:@list,Lolita::Configuration::List)
        end
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
          search_criteria = self.search.run(request.params[:q],request)
          page_criteria = if search_criteria.respond_to?(:where) 
            page_criteria.merge(search_criteria)
          else
            search_criteria
          end
        end
        page_criteria
      end

      # Set columns. Allowed classes are Lolita::Configuration::Columns or
      # Array.
      def columns=(value)
        if value.is_a?(Lolita::Configuration::Columns)
          @columns = value
        elsif value.respond_to?(:each)
          value.each{|possible_column| 
            column(possible_column)
          }
        else
          raise ArgumentError.new("Columns must bet Array or Lolita::Configuration::Columns.")
        end
      end

      # Define columns for list
      def columns(*args,&block)
        if args  && args.any? || block_given?
          @columns = Lolita::Configuration::Columns.new(dbi,*args,&block)
        else
          @columns ||= Lolita::Configuration::Columns.new(dbi)
        end
        @columns
      end

       # Block setter for columns
      def column(*args,&block)
        columns.column(*args, &block)
      end

      def parents
        results = []
        object = self
        while object.respond_to?(:parent) && object.parent
          results << object.parent
          object = object.parent
        end
        results
      end

      def depth
        self.parents.size + 1
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

      def set_default_attributes
        @per ||= Lolita.application.per_page || 10
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

    end
  end
end