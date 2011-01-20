module Lolita
  module Controllers
    module UrlHelpers

      protected

      def lolita_resources_path(*args)
        options=args.extract_options!
        mapping=args[0]
        send(lolita_resource_name(mapping,nil,true),options)
      end
      
      def lolita_resource_path(*args) # TODO test
        options=args.extract_options!
        mapping=args[0]
        send(lolita_resource_name(mapping),options)
      end

      def new_lolita_resource_path(*args)
        options=args.extract_options!
        mapping=args[0]
        send(lolita_resource_name(mapping,:new),options)
      end

      def edit_lolita_resource_path(*args)
        options=args.extract_options!
        options[:id]||=resource.id if resource
        raise "Can edit resource without id." unless options[:id]
        mapping=args[0]
        send(lolita_resource_name(mapping,:edit),options)
      end

      def lolita_resource_name(mapping=nil,action=nil,plural=nil) #TODO test if path is right
        mapping=(mapping||lolita_mapping)
        name=!plural ? mapping.name : mapping.plural
        name="#{mapping.path}_#{name}"
        :"#{action}#{action ? "_" : ""}#{name}_path"
      end
    end
  end
end
