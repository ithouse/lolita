module Lolita
  module Configuration
    module Field
      class Boolean < Lolita::Configuration::Field::Base
        def initialize *args
          @type="boolean"
          super
        end
      end
    end
  end
end
