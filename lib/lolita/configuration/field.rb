module Lolita
  module Configuration
    class Field
      
      attr_accessor :field_set,:nested_for,:type,:options,:record
      attr_writer :name,:title
      attr_reader :dbi,:nested_in,:association_type
      
      def initialize dbi, *args, &block
        @dbi=dbi
        self.set_attributes(*args)
        self.instance_eval(&block) if block_given?
        set_default_values
        validate
      end

      def title(value=nil)
        @title=value if value
        @title
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

      def name value=nil
        self.name=value if value
        @name
      end

      def name=(value)
        @name=value.to_sym
      end

      def type_name
        self.type.to_s.downcase
      end

      def nested_in=(dbi)
        # FIXME need to check if that association is belongs_to or many to many
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

      def record_value
        if self.record
          self.record.send(self.name.to_sym)
        else
          nil
        end
      end
      
      private

      def set_association
        @association=@dbi.reflect_on_association(self.name)
      end
      
      def default_type
        if @association
          Array
        else
          String
        end
      end

      def set_association_type
        if @association
          @association_type=@dbi.association_macro(@association)
        end
      end

      def set_default_values
        self.title||=self.name.to_s.capitalize
        self.options||={}
        set_association
        self.type||=default_type
        set_association_type
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