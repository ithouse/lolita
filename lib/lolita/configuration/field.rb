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
    class Field

      lolita_accessor :name,:title,:field_set,:nested_for,:options, :html_options,:record
      attr_reader :dbi,:nested_in,:association_type
      
      def initialize dbi, *args, &block
        @dbi=dbi
        self.set_attributes(*args)
        self.instance_eval(&block) if block_given?
        set_default_values
        validate
      end

      def type(value=nil)
        @type=value if value
        add_extension unless @extension_added
        @type
      end

      def type=(value)
        @type=value
        add_extension unless @extension_added
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

      def name=(value)
        @name=value.to_sym
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
        if args
          attributes=args.extract_options!
          self.name=args.first if args.first
          attributes.each{|attr,value|
            self.send(:"#{attr}=",value)
          }
        end
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

      def add_extension #TODO test
        @extension_added=true
        set_association
        refactor_type
        set_association_type
        self.extend("Lolita::Configuration::FieldExtensions::#{@type.camelize}".constantize) rescue nil
      end

      
      def set_association #TODO test
        assoc_name=@name.to_s.gsub(/_id$/,"")
        @association=@dbi.reflect_on_association(assoc_name.to_sym) ||
          @dbi.reflect_on_association(assoc_name.pluralize.to_sym)
      end
      
      def refactor_type #TODO test
        @type=if @association
          "collection"
        elsif [:created_at,:updated_at,:type].include?(@name)
          "disabled"
        else
          @type
        end
      end

      def set_association_type #TODO test
        if @association
          @association_type=@dbi.association_macro(@association)
        end
      end

      def set_default_values
        self.title||=self.name.to_s.capitalize
        self.type||="string"
        self.options||={}
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