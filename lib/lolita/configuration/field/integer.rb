module Lolita
  module Configuration
    module Field
      class Integer < Lolita::Configuration::Field::Base
        def initialize *args
          @type="integer"
          super
        end
      end
    end
  end
end
