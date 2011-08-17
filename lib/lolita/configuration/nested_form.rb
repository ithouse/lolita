module Lolita
  module Configuration
    class NestedForm
       @@last_nested_form=0
      
      attr_reader :parent, :options
      attr_accessor :name

      def initialize parent,name=nil, options ={}
        @parent=parent
        @options = options
        self.name=name || "nested_form_#{next_nested_form}"
      end

      def fields
        self.parent.fields.reject{|f| f.nested_form!=self}
      end

      private

      def next_nested_form
        @@last_nested_form+=1
      end
    end
  end
end