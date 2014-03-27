module Lolita
  module Configuration
    class List < Lolita::Configuration::Base
      include Observable
      include Lolita::Builder

      attr_reader :initialized_attributes,:page_criteria
      attr_writer :title

      lolita_accessor :per_page, :pagination_method, :actions

      def initialize(dbp,*args,&block)
        set_and_validate_dbp(dbp)
        set_list_attributes do
          set_attributes(*args)
          self.instance_eval(&block) if block_given?
        end
      end

      def title(new_title = nil)
        if new_title
          @title = new_title
        end
        Lolita::Utils.dynamic_string(@title, :default => dbp.klass.lolita_model_name.human(:count => 2))
      end

      def action name, options = {}, &block
        @actions << decide_and_create_action(name, options, &block)
        @actions.flatten!
      end

      # Allow to crate nested list for list
      def list(*args, &block)
        if args && args.any? || block_given?
          association = dbi.associations[args[0].to_s.to_sym]
          association_dbi = association && Lolita::DBI::Base.create(association.klass)
          raise Lolita::UnknownDBPError.new("No DBI specified for list sublist") unless association_dbi
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
      def columns=(possible_columns)
        if possible_columns.is_a?(Lolita::Configuration::Columns)
          @columns = possible_columns
          @columns.parent = self
        elsif possible_columns.respond_to?(:each)
          possible_columns.each{|possible_column|
            column(possible_column)
          }
        else
          raise ArgumentError.new("Accepts only Enumerable or Lolita::Configuration::Columns.")
        end
      end

      # Define columns for list. On first read if there is no columns they will be created.
      def columns(*args,&block)
        if (args && args.any?) || block_given? || !@columns
          self.columns = Lolita::Configuration::Columns.new(dbi,*args,&block)
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

      # Create or return filter
      def filter(*args,&block)
        if args && args.any? || block_given?
          @filter = Lolita::Configuration::Filter.new(dbi,*args,&block)
          add_observer(@filter)
        end
        @filter
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
        init_default_attributes
        yield if block_given?
        create_default_actions
      end

      def init_default_attributes
        initialize_actions
        @per_page = Lolita.application.per_page || 10
      end

      def create_default_actions
        if !skip_actions? && ( default_actions? || actions_empty?)
          initialize_actions
          @actions << add_edit_action
          @actions << add_destroy_action
        end
      end

      def initialize_actions
        @actions = [] unless @actions.respond_to?(:each)
      end

      def default_actions?
        actions.to_s.to_sym == :default
      end

      def included_default_actions?
        actions.include?(:default)
      end

      def actions_empty?
        (@actions.respond_to?(:each) && @actions.empty?)
      end

      def skip_actions?
        actions.to_s.to_sym == :none
      end

      def decide_and_create_action(name, options ={}, &block)
        if name.to_s == 'default'
          [add_edit_action,add_destroy_action]
        else
          create_action(name,options,&block)
        end
      end

      def create_action name, options = {}, &block
        Lolita::Configuration::Action.new(@dbi,name,options,&block)
      end

      def add_edit_action
        unless actions.detect{|existing_action| existing_action.name == :edit}
          create_action(:edit, &edit_action_block)
        end
      end

      def add_destroy_action
        unless actions.detect{|existing_action| existing_action.name == :destroy}
          create_action(:destroy, &destroy_action_block)
        end
      end

      def edit_action_block
        Proc.new do
          title Proc.new{::I18n.t("lolita.shared.edit")}
          url Proc.new{|view,record| view.send(:edit_lolita_resource_path, :id => record.id)}
        end
      end

      def destroy_action_block
        Proc.new do
          title Proc.new{::I18n.t("lolita.shared.delete")}
          url Proc.new{|view,record| view.send(:lolita_resource_path,:id => record.id)}
          html :method => :delete, :confirm => Proc.new{::I18n.t("lolita.list.confirm")}
        end
      end

    end
  end
end