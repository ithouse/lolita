module Components
  module Lolita
    module ConfigurationComponent
      def link_to_remove_fields(name, f)
        f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
      end

      def link_to_add_fields(name, f, nested_form)
        new_object = nested_form.klass.new
        fields_content = ""
        fields = f.fields_for(nested_form.name, new_object, :child_index => "new_#{nested_form.name}") do |builder|
          self.current_form(builder) do
            fields_content = render_component(nested_form, :"fields")
          end
        end
        link_to_function(name, "add_fields(this, \"#{nested_form.name}\", \"#{escape_javascript(fields_content)}\")")
      end

    end
  end
end
