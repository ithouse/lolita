module Lolita
  module Configuration
    class FieldSet

      attr_reader :parent
      attr_accessor :name

      def initialize parent,name=nil
        @parent=parent
        self.name=name
      end

      def fields
        self.parent.fields.reject{|f| f.field_set!=self}
      end
    end
  end
end