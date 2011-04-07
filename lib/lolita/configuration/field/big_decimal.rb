module Lolita
  module Configuration
    module Field
      class BigDecimal < Lolita::Configuration::Field::Base

        def initialize *args, &block
          @type="big_decimal"
          super
        end
      end
    end
  end
end
