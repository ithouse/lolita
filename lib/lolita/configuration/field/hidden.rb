module Lolita
  module Configuration
    module Field
      class Hidden < Lolita::Configuration::Field::Base
        def initialize *args
          @type="hidden"
          super
        end
      end
    end
  end
end
