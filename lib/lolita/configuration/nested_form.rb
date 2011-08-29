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

      def initialize parent,name=nil, options ={}
        @parent=parent
        @options = options
        self.name=name || "nested_form_#{next_nested_form}"
      end

      def field_style=(value)
        allowed_values = [:normal,:simple]
        raise ArgumentError, "Only #{allowed_values.inspect} are allowed" unless allowed_values.include?(value)
        @field_style = value
      end

      def expandable?
        @expandable == true || (@expandable == nil && macro == :many)
      end

      def dbi
        @parent.dbi
      end

      def fields=(new_fields)
        @fields = new_fields
      end

      def fields
        if @fields
          @fields
        elsif field_rejection_proc
          self.parent.fields.reject(&field_rejection_proc)
        else
          self.parent.fields.reject{|f| f.nested_form!=self}
        end
      end

      def klass
        dbi.reflect_on_association(name).klass
      end

      def macro
        dbi.association_macro(dbi.reflect_on_association(name))
      end

      private

      def next_nested_form
        @@last_nested_form+=1
      end
    end
  end
end