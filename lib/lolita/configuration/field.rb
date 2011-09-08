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

        @@default_type = :string
        lolita_accessor :name,:title,:field_set, :nested_form,:nested_for,:options, :html_options
        attr_reader :dbi,:nested_in
        attr_accessor :dbi_field
        
        def initialize dbi,name,*args, &block
          @dbi=dbi
          self.name = name
          options = args ? args.extract_options! : {}
          type = args[0]

          self.type = type || @@default_type

          self.set_attributes(options)
          if block_given?
            self.instance_eval(&block)
          end
          set_default_values
          validate
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
          @name= value ? value.to_sym : nil
        end

        def nested_in=(dbi)
          unless self.dbi.associations_class_names.include?(dbi.klass.to_s)
            raise Lolita::ReferenceError, "There is no association between #{self.dbi.klass} and #{dbi.klass}"
          end
          if !dbi.is_a?(Lolita::DBI::Base) && !dbi.class.to_s.match(/Lolita::Adapter/)
            raise ArgumentError, "Field can be nested only in Lolita::DBI::Base object." 
          end
          @nested_in=dbi
        end
        
        def nested?
          !self.nested_in.nil?
        end

        def nested_in?(dbi_or_class)
          if dbi_or_class.respond_to?(:klass)
            self.nested_in && self.nested_in.klass==dbi_or_class.klass
          else
            self.nested_in && self.nested_in.klass==dbi_or_class
          end
        end
      
        def set_attributes(attributes)
          excluded_keys = [:name,:type]
          attributes.each{|attr,value|
            unless excluded_keys.include?(attr.to_sym)
              self.send(:"#{attr}=",value)
            end
          }
        end

        def find_dbi_field
          @dbi_field ||= self.dbi.fields.detect{|field|
            field.name.to_s == self.name.to_s || (field.association && field.association.name.to_s == self.name.to_s)
          }
        end

        private
       
        def builder_local_variable_name 
          :field
        end

        def set_default_values
          self.options||={}
          self.html_options ||= {}
          @html_options[:class] = if @html_options[:class]
            "#{@html_options[:class]} #{self.type}"
          else
            self.type.to_s
          end
          recognize_real_name
        end

        def recognize_real_name
          if @dbi_field && @dbi_field.association && !@dbi_field.association.polymorphic? && @dbi_field.association.macro == :one
            self.name = @dbi_field.name
          end
        end

        def validate
          unless self.name
            raise Lolita::FieldNameError, "Field must have name."
          end
        end
      end
    end
  end
end
