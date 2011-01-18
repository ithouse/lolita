module Lolita
  module Controllers
    module UrlHelpers

      protected
      def lolita_resource_path(mapping=nil) # TODO test
        send(lolita_resource_name(mapping))
      end

      def new_lolita_resource_path(mapping=nil)
        send(lolita_resource_name(mapping,:new))
      end

      def edit_lolita_resource_path(mapping=nil)
        send(lolita_resource_name(mapping,:edit))
      end

      def lolita_resource_name(mapping=nil,action=nil) #TODO test if path is right
        mapping=(mapping||lolita_mapping)
        name=action ? mapping.name : mapping.plural
        name="#{mapping.path}_#{name}"
        puts :"#{action}#{action ? "_" : ""}#{name}_path"
        :"#{action}#{action ? "_" : ""}#{name}_path"
      end
    end
  end
end
