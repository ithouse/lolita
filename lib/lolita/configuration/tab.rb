module Lolita
  module Configuration
    # Tab is used as a container for different type of resource content.
    # It can contain fields, images, audio, video files, maps and other stuff.
    # Each tab has its own type and unique index.
    # Tab contain following parts, that also are configurable through block or
    # arguments passed to tab.
    # * <tt>nested_fields_for</tt> Create fields for different DB table/collection than given.
    # * <tt>field_set</tt> Create fields set for ease use in builders.
    # * <tt>field</tt> Create field in tab, fields also can be included in #nested_fields_for and
    #   #field_set
    # * <tt>default_fields</tt>
    class Tab

      # For different types there are different builders(cells)
      @@available_types=[:content]
      # Any tab has unique index, index may not be consecutive
      @@last_index=0
      
      attr_accessor :dbi,:type,:name,:title,:current_fieldset,:current_dbi
      attr_reader :field_sets,:nested_form,:index

      # To create new tab the following parametrs need to be provided.
      # * <tt>dbi</tt> Lolita::DBI::Base object, that represents database.
      # * <tt>*args</tt> See #set_attributes, for how these args are processed.
      # * <tt>&block</tt> Block can be passed, anything in block will be evaled for current instance.
      def initialize dbi,*args,&block
        @fields=[]
        @field_sets=[]
        @index=next_index
        self.dbi=dbi
        self.current_dbi=dbi
        self.set_attributes(*args)
        self.instance_eval(&block) if block_given?
        validate
      end

      # Field setter method, accpet <i>*args</i> and <i>&block</i> to be passed.
      # For details how to pass args and block see Lolita::Configuration::Field.
      # Return field itself.
      def field *args, &block
        field=Lolita::Configuration::Field.new(self.current_dbi,*args,&block)
        field.field_set=current_fieldset
        if self.current_dbi!=self.dbi
          field.nested_in=self.dbi
        end
        @fields<<field
        field
      end

      # Return all fields in tab. If fields not defined then set default fields.
      def fields
        if @fields.empty?
          set_default_fields
        end
        @fields
      end

      # Set all fields in tab. Accept <code>fields</code> as Array.
      # Each array element can be Lolita::Configuration::Field object or
      # Hash, that will be passed to #field method.
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

      # Create fields for tab from database.
      # See Lolita::Adapter classes for use of DB field method.
      def default_fields
        self.current_dbi.fields.each{|db_field|
          self.field(db_field)
        }
      end

      # Add tab nested fields for <em>class_or_name</em> and <em>&block</em>
      # that will be evaluted in current tab instance.
      def nested_fields_for class_or_name,&block
        current_class=get_class(class_or_name)
        self.current_dbi=Lolita::DBI::Base.new(current_class)
        self.instance_eval(&block)
        self.current_dbi=self.dbi
      end

      # Return nested field for given <em>class_or_name</em>
      def nested_fields_of class_or_name
        current_class=get_class(class_or_name)
        self.fields.select{|field|
          field.nested_in?(@dbi) && field.dbi.klass==current_class
        }
      end

      # Create new field_set for current tab with given _name_ and <em>&block</em>
      # that will be evaluted in current tab instance.
      def field_set name,&block
        field_set=Lolita::Configuration::FieldSet.new(self,name)
        self.current_fieldset=field_set
        @field_sets<<field_set
        self.instance_eval(&block)
        self.current_fieldset=nil
      end

      def fields_with_field_set
        used_fieldsets=[]
        self.fields.each{|field|
          if !field.field_set || (!used_fieldsets.include?(field.field_set))
            if field.field_set
              yield field.field_set.fields,field.field_set
              used_fieldsets<<field.field_set
            else
              yield field,nil
            end
          end
        }
      end
      # tab.field do
      #  tab.fields_with_fieldset do |field,fieldset|
      #    =field
      #  end


      # Set attributes from given <em>*args</em>.
      # First element of args is used as <i>type</i> other interpreted as options.
      # Every Hash key is used as setter method, and value as method value.
      # ====Example
      #     set_attributes(:content,:field=>{:name=>"My Field"})
      #     set_attributes(:field=>{:name=>"My Field"})
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

      def set_default_fields
        if @type==:content && @fields.empty?
          default_fields
        end
      end

      def get_class(str_or_sym_or_class)
        str_or_sym_or_class.is_a?(Class) ? str_or_sym_or_class : str_or_sym_or_class.to_s.camelize.constantize
      end
      
      def validate
        if type==:default && fields.empty?
          raise Lolita::NoFieldsGivenError, "At least one field must be specified for default tab."
        end
      end

      def next_index
        @@last_index+=1
      end
      
      class << self
        def default_types
          @@available_types
        end
      end
    end
  end
end