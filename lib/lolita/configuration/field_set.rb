module Lolita
  module Configuration
    class FieldSet

      @@last_fieldset=0
      
      attr_reader :parent
      attr_accessor :name

      def initialize parent,name=nil
        @parent=parent
        self.name=name || "fieldset_#{next_fieldset}"
      end

      def fields
        self.parent.fields.reject{|f| f.field_set!=self}
      end

      private

      def next_fieldset
        @@last_fieldset+=1
      end
    end
  end
end