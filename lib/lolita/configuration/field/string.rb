module Lolita
  module Configuration
    module Field
      class String < Lolita::Configuration::Field::Base

        def initialize *args, &block
          @type="string"
          super
        end
        
      end
    end
  end
end
