module Lolita
  module Configuration
    class List
      include Lolita::Builder
       
      attr_reader :dbi,:initialized_attributes
      attr_accessor :parent,:association_name

      lolita_accessor :per_page, :pagination_method
      
      def initialize(dbi,*args,&block)
        @dbi = dbi
        raise Lolita::UnknownDBIError.new("No DBI specified for list") unless @dbi
        set_attributes(*args)
        self.instance_eval(&block) if block_given?
        set_default_attributes
      end

      def list(*args, &block)
        if args && args.any? || block_given?
          association = dbi.associations[args[0].to_s.to_sym]
          association_dbi = association && Lolita::DBI::Base.create(association.klass)
          raise Lolita::UnknownDBIError.new("No DBI specified for list sublist") unless association_dbi
          Lolita::LazyLoader.lazy_load(self,:@list,Lolita::Configuration::List,association_dbi, :parent => self, :association_name => association.name,&block)
        else
          @list
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
        page_criteria = page_dbi(request).paginate(current_page,@per,:request => request, :pagination_method => @pagination_method)
        if self.search
          search_criteria = self.search.run(request && request.params[:q] || "",request)
          page_criteria = if search_criteria.respond_to?(:where) 
            page_criteria.merge(search_criteria)
          elsif search_criteria.nil?
            page_criteria
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
          @columns.parent = self
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
          @columns.parent = self
        elsif !@columns
          @columns = Lolita::Configuration::Columns.new(dbi)
          @columns.parent = self
        end
        @columns
      end

       # Block setter for columns
      def column(*args,&block)
        columns.column(*args, &block)
      end

      # Return mapping that class matches dbi klass.
      def mapping
        if @mapping.nil?
          @mapping = (Lolita.mappings.detect{|name,mapping| mapping.to == dbi.klass} || []).last || false
        end
        @mapping
      end

      def by_path(path)
        object = self
        while path.any?
          part = path.pop.match(/(l|c)_(\w+)/)
          object = if part[1] == "l"
            object.list
          else
            object.columns.by_name(part[2]).list
          end
        end
        object
      end

      # Nested list method. Return all parent object where first is self.parent and last is root list or column.
      def parents
        unless @parents
          @parents = []
          object = self
          while object.respond_to?(:parent) && object.parent
            @parents << object.parent
            object = object.parent
          end
        end
        @parents
      end

      def root
        parents.last
      end

      # Return Hash with key <em>:nested</em> thas is Hash with one key that is foreign key that links parent with this list.
      def nested_options_for(record)
        if self.parent
          association = self.parent.dbi.reflect_on_association(self.association_name)
          attr_name = association.macro == :many_to_many ? :id : association.key
          base_options = {
            attr_name => association.through? ? record.send(association.through).id : record.id,
            :parent => self.root.dbi.klass.to_s,
            :path => self.parents.map{|parent| parent.is_a?(Lolita::Configuration::List) ? "l_" : "c_#{parent.name}"}
          }
          if association.macro == :many_to_many
            base_options.merge({
              :association => association.name
            })
          end
          {:nested => base_options}
        end
      end

      # Return how deep is this list, starging with 1.
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

      def page_dbi(request)
        # if request && request.respond_to?(:params) && request.params[:nested]
        #   nested_page_dbi(request)
        # else
          dbi
       # end
      end

      def nested_page_dbi(request)
        if request.params[:nested] && request.params[:nested][:path]
          if n_list = self.by_path(request.params[:nested][:path])
            n_list.dbi
          else
            raise Lolita::UnknownDBIError.new("Request asked for nested list for list, but none is found! Please specify list in list for #{dbi.klass}")
          end
        else
          raise Lolita::UnknownDBIError.new("Request asked nested list '#{request.params[:nested]}', but :path was wrong.")
        end
      end

    end
  end
end