module Lolita
  module Configuration
    # Lolita::Configuration::Tabs is container class that holds all
    # tabs for each lolita instance. 
    # Also it has some useful methods.

    class Fields
      include Enumerable
      include Lolita::ObservedArray

      def initialize *args,&block
        @fields=[]
        self.instance_eval(&block) if block_given?
      end

      def clear
        @fields.clear
      end
      
      def by_name(name)
        @fields.detect{|field| (field.name==name.to_sym || field.name=="#{name}_id".to_sym) }
      end

      private

      def collection_variable
        @fields
      end

      def build_element(element,&block)
        element
      end

    end
  end
end