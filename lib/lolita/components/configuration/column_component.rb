module Lolita
  module Components
    module Configuration

# Should include routes helper and lolita urls helpers
# - nested_list_options = column.list && {}  || {}
# - content_text = column.formatted_value(record,self)
# %td{{:class => column.list && "with-nested-list"}.merge(nested_list_options)}= column.list ? link_to(content_text,"#") : content_text

      class ColumnComponent < Lolita::Components::Base

        def td_attributes(record)
          {
            :class => parent.list && "with-nested-list"
          }.merge(nested_list_options(record))
        end

        def td_value(record,view)
          column.formatted_value(record)
        end

        def nested_list_options parent
          parent.list && {
            :"data-nested-list-url" => lolita_resources_path(column.list.mapping, column.list.nested_options_for(record))
          }
        end
      end

    end
  end
end