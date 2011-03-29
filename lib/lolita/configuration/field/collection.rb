module Lolita
  module Configuration
    class CollectionField < Lolita::Configuration::Field
       lolita_accessor :conditions,:text_method,:value_method,:find_options,:association_type
      

        def initialize *args,&block
          @type="collection"
          super
          set_association_type
        end

        def options_for_select &block
          @options_for_select=block if block_given?
          @options_for_select
        end

        # Collect values for collection type field.
        # Uses <code>text_method</code> for content. By default it search for
        # first _String_ type field in DB. Uses <code>value_method</code> for value,
        # by default it it is <code>id</code>. Use <code>conditions</code> or
        # <code>find_options</code> for advanced search. When <code>find_options</code>
        # is used, than <code>conditions</code> is ignored.
        def association_values() #TODO test
          @association_values||=if options_for_select
            options_for_select
          elsif @association
            klass=@dbi.association_class_name(@association).camelize.constantize
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

        private

        def set_association_type #TODO test
          if @association
            @association_type||=@dbi.association_macro(@association)
          end
        end

        def default_text_method(klass)
          assoc_dbi=Lolita::DBI::Base.new(klass)
          field=assoc_dbi.fields.detect{|f| f[:type].downcase=="string"}
          if field
            field[:name]
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