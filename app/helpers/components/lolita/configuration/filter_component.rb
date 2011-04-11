module Components
  module Lolita
    module FilterComponent
      def options_for_filter(field)
        selected = params[field.filter_short_name]
        if field.options_for_select
          field.options_for_select
        else

        end
        options_from_collection_for_select( or field.association_values.respond_to?(:call) ? field.association_values.call(self) : field.association_values)
      end
    end
  end
end