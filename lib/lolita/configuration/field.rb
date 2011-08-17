module Lolita
  module Configuration
    # Lolita::Configuration::Field is class that allow to configure fields.
    # To change behaviour of field you can use these attributes
    # * <tt>name</tt> - field name, used to set or get value from related ORM object
    # * <tt>type</tt> - can change the way field is shown and how data is formated
    # * <tt>field_set</tt> - define field set that field belongs to. See Lolita::Configuration::FieldSet
    # * <tt>nested_in</tt> - define field for different Lolita::DBI instance, than given. This is used
    #   to create nested fields in one form for related models. Like user and profile, where in user
    #   form there are fields from profile that can be manipulated when user is changed or created.
    # * <tt>optinos</tt> - specific options for different type of fields, see Lolita::Configuration::FieldExtensions for details
    # * <tt>html_options</tt> - used to change field HTML output,like class or style etc.
    # 
    # To define field in ORM class through lolita configuration block
    # ====Example
    #     lolita do
    #       tab do
    #         field :email
    #         field :user_id, :type=>"string"
    #         field :body do
    #            title "Full text" 
    #            html_options :class=>"full_text"
    #         end
    #       end
    #     end
    module Field

      class Base
        include Lolita::Builder

        @@default_type="string"
        lolita_accessor :name,:title,:field_set, :nested_form,:nested_for,:options, :html_options,:record,:association
        attr_reader :dbi,:nested_in
        
        def initialize dbi, *args, &block
          @dbi=dbi
          before_init(*args)
          begin
            self.set_attributes(*args)
            if block_given?
              self.instance_eval(&block)
              process_type unless @type 
            end
            set_default_values
            validate
          rescue Exception=>e
            unless Lolita::Configuration::Field.temp_object?
              raise e
            end
          end
        end
        
        def value value=nil, &block
          self.send(:value=,value,&block) if value || block_given?
          unless @value
            self.record_value
          else
            if @value.is_a?(Proc)
              @value.call(self)
            else
              @value
            end
          end
        end

        def value=(value=nil,&block)
          if block_given?
            @value=block
          else
            @value=value
          end
        end
        
        def title(value=nil)
          @title=value if value
          @title||=@dbi.klass.human_attribute_name(@name)
          @title
        end

        def type value=nil
          @type=value.to_s.underscore if value
          @type
        end

        def type=(value)
          @type=value ? value.to_s.underscore : nil
        end

        def name=(value)
          @name=value ? value.to_sym : nil
        end

        def type_name
          self.type.to_s.downcase
        end

        def nested_in=(dbi)
          unless self.dbi.associations_class_names.include?(dbi.klass.to_s)
            raise Lolita::ReferenceError, "There is no association between #{self.dbi.klass} and #{dbi.klass}"
          end
          raise ArgumentError, "Field can be nested only in Lolita::DBI::Base object." unless dbi.is_a?(Lolita::DBI::Base)
          @nested_in=dbi
        end
        
        def nested?
          !self.nested_in.nil?
        end

        def nested_in?(dbi_or_class)
          if dbi_or_class.is_a?(Lolita::DBI::Base)
            self.nested_in && self.nested_in.klass==dbi_or_class.klass
          else
            self.nested_in && self.nested_in.klass==dbi_or_class
          end
        end
      

        def set_attributes(*args)
          @given_attributes.each{|attr,value|
            if (attr.to_sym==:type && !@type) || attr.to_sym!=:type
              self.send(:"#{attr}=",value)
            end
          }
        end

        # TODO is this useable
        def record_value #TODO test
          if self.record
            self.record.send(self.name.to_sym)
          else
            nil
          end
        end

        private
       
        def builder_local_variable_name 
          :field
        end

        def set_default_values
          self.options||={}
          self.html_options ||= {}
        end

         def before_init *args
          extract_args *args
          set_name
          if @name
            process_type
          end
        end

        def process_type
          set_association
          set_type_from_args
          set_type
        end

         def extract_args *args
          if args
            @given_args=args
            @given_attributes=@given_args.extract_options!
          else
            @given_args=[]
            @given_attributes={}
          end
        end

        def set_name
          if @given_args.first
            self.name=@given_args.first 
          else
            self.name=@given_attributes[:name]
          end
        end

        def set_type_from_args
          self.type=@given_args[1] if @given_args[1]
        end

        def set_type
          if !@type
           if @association
                self.type="array"
            elsif dbi_field=self.dbi.fields.detect{|f| f[:name].to_s==@name.to_s}
              self.type=dbi_field[:type]
              self.options=dbi_field[:options]
            end
          end
          if @type.nil? || @type.to_s.downcase=="object"
            self.type=@@default_type
          end
        end

        # Need here because this don't know how to recognize association.
        # TODO maybe need move to adapter, and it is converted there
        def set_association #TODO test
          assoc_name=@name.to_s.gsub(/_id$/,"") 
          @association||=@dbi.reflect_on_association(assoc_name.to_sym) ||
            @dbi.reflect_on_association(assoc_name.pluralize.to_sym)
        end

        def validate
          unless self.name
            raise Lolita::FieldNameError, "Field must have name."
          end
          #FIXME need this validation
          #        if !@value && !@dbi.klass.instance_methods.include?(self.name.to_s)
          #          raise Lolita::FieldNameError, "#{@dbi.klass} must respond to #{self.name} method."
          #        end
        end
       
      end
    end
  end
end