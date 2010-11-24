module Lolita
  module Configuration
    class Tab

      @@available_types=[:content]
      attr_accessor :dbi,:type,:name,:title,:current_fieldset,:current_dbi
      attr_reader :field_sets,:nested_form
      def initialize dbi,*args,&block
        @fields=[]
        @field_sets=[]
        self.dbi=dbi
        self.current_dbi=dbi
        self.set_attributes(*args)
        self.instance_eval(&block) if block_given?
        validate
      end

      def field *args, &block
        field=Lolita::Configuration::Field.new(self.current_dbi,*args,&block)
        field.field_set=current_fieldset
        if self.current_dbi!=self.dbi
          field.nested_in=self.dbi
        end
        @fields<<field
        field
      end
      
      def fields
        @fields
      end

      def fields=(fields)
        @fields=[]
        if fields.is_a?(Array)
          fields.each{|field_attr|
            if field_attr.is_a?(Lolita::Configuration::Field)
              @fields<<field_attr
            else
              self.field(field_attr)
            end
          }
        end
      end

      def default_fields
        self.current_dbi.fields.each{|db_field|
          self.field(db_field)
        }
      end

      def nested_fields_for class_or_name,&block
        current_class=get_class(class_or_name)
        self.current_dbi=Lolita::DBI::Base.new(current_class)
        self.instance_eval(&block)
        self.current_dbi=self.dbi
      end

      def nested_fields_of class_or_name
        current_class=get_class(class_or_name)
        self.fields.select{|field|
          field.nested_in?(@dbi) && field.dbi.klass==current_class
        }
      end
      
      def field_set name,&block
        field_set=Lolita::Configuration::FieldSet.new(self,name)
        self.current_fieldset=field_set
        @field_sets<<field_set
        self.instance_eval(&block)
        self.current_fieldset=nil
      end
      
      def set_attributes *args
        if args
          options=args.extract_options!
          self.type=args.first || :default
          options.each{|method,options|
            self.send(:"#{method}=",options)
          }
        end
        
      end

      private

      def get_class(str_or_sym_or_class)
        str_or_sym_or_class.is_a?(Class) ? str_or_sym_or_class : str_or_sym_or_class.to_s.camelize.constantize
      end
      
      def validate
        if type==:default && fields.empty?
          raise Lolita::NoFieldsGivenError, "At least one field must be specified for default tab."
        end
      end
      
      class << self
        def default_types
          @@available_types
        end
      end
    end
  end
end