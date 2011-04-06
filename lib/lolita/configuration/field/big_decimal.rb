module Lolita
  module Configuration
    class BigDecimalField < Lolita::Configuration::Field

      def initialize *args, &block
        @type="big_decimal"
        super
      end
    end
  end
end