# coding: utf-8
module Lolita
  module Configuration
    # Lolita::Configuration::Filter is for filtering data in list view.
    # By now it supports these field types:
    # - Array
    # - Boolean
    #  
    # To use it, call "filter" method in list block, filter method accepts field names
    # as arguments. You can pass block and configure each field. Field configuration is just like in tab configuration.
    #
    # === Examples
    #    
    #    # this will build country select field and is_deleted checkbox
    #    list do
    #      filter :country, :is_deleted
    #    end
    #
    #    # For example you have text field "status" with values opened,closed,rejected
    #    list do
    #      filter do
    #        field :status, :array, :values=> %w(open closed rejected)
    #        field :is_deleted, :title => "Deleted"
    #      end
    #    end
    #
    class Filter
      include Lolita::Builder
      attr_reader :dbi

      def initialize(dbi,*args,&block)
        @dbi = dbi
        @fields = Lolita::Configuration::Fields.new
        set_attributes(*args)
        self.instance_eval(&block) if block_given?
      end

      def field *args, &block
        field = Lolita::Configuration::Factory::Field.create(self.dbi,*args,&block)
        @fields << field
        field
      end

      def fields(*args, &block)
        Array(args).each do |field_name|
          f = field(field_name)
          f.instance_eval(&block) if block_given?
        end
        @fields
      end

      def resource(params)
        if klass = fields.any? ? fields.first.dbi.klass : nil
          klass.new(params[klass.to_s.underscore.to_sym]).extend(Module.new{def persisted?; true; end})
        end
      end

      def search *args, &block
        if args && args.any? || block_given?
          @search = Lolita::Configuration::Search.new(self.dbi,*args, &block)
        else
          @search
        end
      end

      def update method_name, list, request
        filter_params = request && request.params && request.params[:filter]
        page_criteria = if method_name == :paginate && self.search && filter_params
          search_criteria = self.search.run(nil,request)
          page_criteria = if search_criteria.respond_to?(:where)
            list.page_criteria.merge(search_criteria)
          elsif search_criteria.nil?
            list.page_criteria
          else
            search_criteria
          end
        else
          list.page_criteria.merge(self.dbi.filter(filter_params || {}))
        end
        list.instance_variable_set(:@page_criteria,page_criteria)
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
            fields *args
          end
        end
      end
    end
  end
end
