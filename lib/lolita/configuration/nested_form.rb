module Lolita
  module Configuration
    # Accept those attributes
    # * <tt>:name</tt> - Name of nested relation, like :comments.
    # * <tt>:field_style</tt> - Is fields rendered with as normal (with lable and staff) or like in table (:simple). Default :simple
    # * <tt>:expandable</tt> - Show or not "Add new" and "Delete" links in form,
    # by default, it is expandable if association macro is :many
    # * <tt>:field_rejection_proc</tt> - Proc, that contains condition of how to reject field. 
    # By default form rejects all fields from parent tab that doesn't have current form as field nested_form
    # ====Example
    #    form = Lolita::Configuration::NestedForm.new(Lolita::Configuration::Tab::Content.new,:comments)
    #    form.field_rejection_proc = Proc.new{|field|
    #       field.name.to_s.match(/_id$/)
    #    }
    #    # form exclude all fields that ends with _id
    class NestedForm
      include Lolita::Builder
      @@last_nested_form=0
      
      attr_reader :parent, :options, :field_style
      attr_accessor :name, :expandable, :field_rejection_proc
      attr_writer :build_method

      def initialize parent,name=nil, options ={}
        @parent=parent
        @options = options
        self.name=name || "nested_form_#{next_nested_form}"
        set_attributes_from(options)
      end

      def allow_destroy?
        dbi.klass.nested_attributes_options[name][:allow_destroy]
      end

      def update_only?
        dbi.klass.nested_attributes_options[name][:update_only]
      end

      def build_method
        @build_method || self.name
      end
      # Set field style - normal or simple. Default - normal.      
      def field_style=(value)
        allowed_values = [:normal,:simple]
        raise ArgumentError, "Only #{allowed_values.inspect} are allowed" unless allowed_values.include?(value)
        @field_style = value
      end

      # Detect if it's possible to add more than one field group, like if model has many other objects.
      def expandable?
        @expandable == true || (@expandable == nil && macro == :many)
      end

      # Create field, that is not real field, but represents nested attributes as one.
      # It is used to create label.
      def as_field
        Lolita::Configuration::Factory::Field.add(dbi,self.name, :string)
      end

      # Parent (a.k.a tab) dbi
      def dbi
        @parent.dbi
      end

      # Fields setter. Fields should be array and each element should be Lolita::Configuration::Field object.
      def fields=(new_fields)
        @fields = new_fields
      end

      # Return all fields. Each time fields ar returned from @fields if its defined or calculated by using #field_rejection_proc
      # or collected from parent (tab) where fields nested form is same with self.
      def fields
        if @fields
          @fields
        elsif field_rejection_proc
          self.parent.fields.reject(&field_rejection_proc)
        else
          self.parent.fields.reject{|f| f.nested_form!=self}
        end
      end

      # Parent (tab) dbi klass
      def klass
        dbi.reflect_on_association(name).klass
      end

      # Parent (tab) dbi klass reflection with #name and macros of that.
      def macro
        dbi.reflect_on_association(name).macro
      end

      private

      def next_nested_form
        @@last_nested_form+=1
      end

      def set_attributes_from(options)
        options.each{|key,value|
          instance_variable_set(:"@#{key}",value)
        }
      end
    end
  end
end