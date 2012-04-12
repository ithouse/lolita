module Lolita
  module Controllers
    module SinatraUrlHelpers

      def __mapping_and_options_from_args__(*args)
        options = args.extract_options!
        mapping = args[0] || lolita_mapping
        [mapping,options]
      end

      def __to_url__ path,options
        full_path = [path,__hash_to_url__(options)].reject{|element| element.blank?}.join("?")
        url(full_path)
      end

      def __hash_to_url__ options = {}
        options.map{|k,v| %Q{#{k}=#{v}}}.join("&")
      end

       # Path for index.
      def lolita_resources_path(*args)
        mapping, options = __mapping_and_options_from_args__(*args)
        __to_url__(mapping.controller,options)
      end

      # Path for show, create and destroy
      def lolita_resource_path(*args) 
        mapping, options = __mapping_and_options_from_args__(*args)
        __to_url__("#{mapping.controller}/#{resource.id}", options)
      end

      # Path for new.
      def new_lolita_resource_path(*args)
        mapping, options = __mapping_and_options_from_args__(*args)
        __to_url__("#{mapping.controller}/new",options)
      end

      # Path for edit.
      def edit_lolita_resource_path(*args)
        mapping, options = __mapping_and_options_from_args__(*args)
        __to_url__("#{mapping.controller}/#{resource.id}/edit",options)
      end
    end
  end
end