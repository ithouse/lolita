module Lolita
  module Configuration
    module Field
      class Enum < Lolita::Configuration::Field::Base

        def values value=nil, &block
          @values=value || block if value || block_given?
          @values
        end

        def view_values(view)
          record = view.send(:current_form).object
          if values.respond_to?(:call)
            values.call(view)
          else
            values || default_values
          end
        end

        private

        def default_values
          dbi_field.limit || [] rescue []
        end

      end
    end
  end
end