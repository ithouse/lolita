module Lolita
  module Configuration
    class DatetimeField < Lolita::Configuration::Field
      def initialize *args
        @type="datetime"
        super
      end
    end
  end
end