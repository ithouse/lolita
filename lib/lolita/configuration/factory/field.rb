module Lolita
  module Configuration
    module Factory
      class Field
        class << self
        # There are three ways to add field.
        # *<tt>first</tt> - Pass name and type
        #   Field.add(dbi,"name","type")
        # *<tt>second</tt> - Pass it through hash
        #   Field.add(dbi,:name => "name", :type => "type")
        # *<tt>third</tt> - Pass dbi_field
        #   Field.add(dbi,:dbi_field => dbi.fields.first)
        def create(dbi,*args,&block)
          
          options = args ? args.extract_options! : {}
          dbi_field = options[:dbi_field]
          name = args[0] || options[:name] || (dbi_field ? dbi_field.name : nil)
          dbi_field ||= dbi.field_by_name(name)
          dbi_field ||= dbi.field_by_association(name)
          association ||= detect_association(dbi,name)

          type = args[1] || options[:type] || 
            (association ? :array : nil ) ||
            (dbi_field ? dbi_field.type : nil) || 
            :string
          options[:dbi_field] = dbi_field
          if !name || !type
            raise Lolita::FieldTypeError, "type not defined. Set is as second argument or as :dbi_field where value is Adapter::[ORM]::Field object."
          else
            field_class(type).new(dbi,name,type,options,&block)
          end

        end

        alias :add :create

        def detect_association(dbi,name)
          dbi.associations[name.to_sym]
        end

        def field_class(name)
          ("Lolita::Configuration::Field::"+name.to_s.camelize).constantize
        end
      end 
      
      end
    end
  end
end