module Lolita
  module Configuration
    # Field Extensions is used to extend Field instances. FieldExtensions allow
    # different field types have same property with different functionality. For
    # example, <code>:find_options</code>, it is possible to avoid <code>order</code>
    # and <code>group</code> usage when it is not neccessary and allow when you
    # need it.
    # It depends on field
    # _type_. Each different field type, can have one extension module. Instance
    # will be automaticly extended when type is assigned, therefor type should
    # be called before any type-specific method is called.
    module FieldExtensions
      module Collection

        lolita_accessor :conditions,:text_method,:value_method,:find_options

        # Collect values for collection type field.
        # Uses <code>text_method</code> for content. By default it search for
        # first _String_ type field in DB. Uses <code>value_method</code> for value,
        # by default it it is <code>id</code>. Use <code>conditions</code> or
        # <code>find_options</code> for advanced search. When <code>find_options</code>
        # is used, than <code>conditions</code> is ignored.
        def association_values() #TODO test
          if @association
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
        end

        private

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
        # MODULE end
      end
    end
  end
end