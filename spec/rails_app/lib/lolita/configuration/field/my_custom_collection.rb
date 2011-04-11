module Lolita
  module Configuration
    module Field
      class MyCustomCollection < Lolita::Configuration::Field::Array
        
          def initialize *args,&block
            super
            @type="my_custom_collection"
          end

      end
    end
  end
end