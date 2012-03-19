module Lolita
  module Configuration
    class List < Lolita::Configuration::Base
      include Observable
      include Lolita::Builder
       
      attr_reader :initialized_attributes,:page_criteria

      lolita_accessor :per_page, :pagination_method, :actions
      
      def initialize(dbi,*args,&block)
        set_and_validate_dbi(dbi)
        set_list_attributes
        set_attributes(*args)
        self.instance_eval(&block) if block_given?
        set_default_attributes
      end

      def action name, options = {}, &block
        @actions << Lolita::Configuration::Action.new(@dbi,name,options,&block)
      end

      def list(*args, &block)
        if args && args.any? || block_given?
          association = dbi.associations[args[0].to_s.to_sym]
          association_dbi = association && Lolita::DBI::Base.create(association.klass)
          raise Lolita::UnknownDBIError.new("No DBI specified for list sublist") unless association_dbi
          Lolita::LazyLoader.lazy_load(self,:@list,Lolita::Configuration::NestedList,association_dbi, self, :association_name => association.name,&block)
        else
          @list
        end
      end

      # For details see Lolita::Configuration::Search
      def search *args, &block
        if (args && args.any?) || block_given?
          @search = Lolita::Configuration::Search.new(self.dbi,*args,&block)
          add_observer(@search)
        end
        @search
      end

      # Return page for list display. Method requires two arguments:
      # * <tt>current_page</tt> - number of current page
      # * <tt>request (optional) </tt> - request that is passed to adapter that passes this to model when #pagination_method is defined
      def paginate(current_page, request = nil)
        changed
        @page_criteria = dbi.paginate(current_page,@per_page,:request => request, :pagination_method => @pagination_method)
        notify_observers(:paginate,self,request)
        @page_criteria
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

      # checks if filter defined
      def filter?
        @filter.is_a?(Lolita::Configuration::Filter)
      end

      # Filter by now works only for these field types:
      # - belongs_to
      # - boolean
      #
      def filter(*args,&block)
        if args && args.any? || block_given?
          @filter = Lolita::Configuration::Filter.new(dbi,*args,&block)
          add_observer(@filter)
        else
          @filter
        end
      end

      def set_default_attributes
        @per_page ||= Lolita.application.per_page || 10
      end

      def by_path(path)
        path = path.dup
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

      private

      def set_list_attributes
        @actions = []
        action :edit do 
          title ::I18n.t("lolita.shared.edit")
          url Proc.new{|view,record| view.send(:edit_lolita_resource_path, :id => record.id)}
        end
        action :destroy do 
          title ::I18n.t("lolita.shared.delete")
          url Proc.new{|view,record| view.send(:lolita_resource_path,:id => record.id)}
          html :method => :delete, :confirm => ::I18n.t("lolita.list.confirm"), :remote => true
        end
      end

    end
  end
end