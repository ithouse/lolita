module Lolita
  module Processors
    class RequestProcessor

      attr_accessor :scope

      def self.respond_to(mapping,scope,action) 
        action_processor = "Lolita::Processors::RequestProcessor::#{action.to_s.camelize}ActionProcessor".constantize.new(mapping,scope)
        action_processor.respond
      end

      def initialize(mapping,scope)
        @mapping = mapping
        @scope = scope
      end

      def resource_class
        @scope.resource_class
      end

      class IndexActionProcessor < self

        def respond
          build_response = resource_class.lolita.list.build(:page => page)
          scope.instance_variable_set(:"@component_builder",build_response)
          scope.haml :"lolita/rest/index.html", :layout => :"layouts/lolita/application.html"
        end

        def page
          resource_class.lolita.list.paginate(1)
        end

      end

    end

  end
end