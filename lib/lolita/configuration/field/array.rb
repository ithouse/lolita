module Lolita
  module Configuration
    module Field
      
      class Array < Lolita::Configuration::Field::Base
        lolita_accessor :conditions,:text_method,:value_method,:find_options,:association,:include_blank

        def initialize dbi,name,*args, &block
          self.builder="select"
          @include_blank=true
          super
          self.find_dbi_field unless self.dbi_field
          @association = self.dbi_field ? self.dbi_field.association : nil
        end

        def options_for_select=(value=nil)
          @options_for_select=value
        end

        def options_for_select value=nil, &block
          @options_for_select=value || block if value || block_given?
          @options_for_select
        end

        # Collect values for array type field.
        # Uses <code>text_method</code> for content. By default it search for
        # first _String_ type field in DB. Uses <code>value_method</code> for value,
        # by default it it is <code>id</code>. Use <code>conditions</code> or
        # <code>find_options</code> for advanced search. When <code>find_options</code>
        # is used, than <code>conditions</code> is ignored.
        def association_values() #TODO test
          @association_values=if options_for_select
            options_for_select
          elsif @association
            klass=@association.klass
            current_text_method=@text_method || default_text_method(klass)
            current_value_method=@value_method || :id
            options=@find_options || {}
            options[:conditions]||=@conditions

            klass.find(:all,options).map{|r|
              [r.send(current_text_method),r.send(current_value_method)]
            }
          else
            []
          end
          @association_values
        end

        # used in views for shorter accessing to values
        def view_values(view)
          values = association_values
          if values.respond_to?(:call)
            values.call(view)
          else
            association_values
          end
        end

      private

      def default_text_method(klass)
        assoc_dbi=Lolita::DBI::Base.create(klass)
        field=assoc_dbi.fields.detect{|f| f.type.to_s=="string"}
        if field
          field.name
        else
          raise Lolita::FieldTypeError, %^
          Can't find any content field in #{assoc_dbi.klass}.
          Use text_method in #{klass} to set one.
          ^
        end
      end
    end
  end
end
end
