module Lolita
  module Configuration
    class DatetimeField < Lolita::Configuration::Field
      attr_accessor :format
      def initialize *args
        @type="datetime"
        super
      end
    end
  end
end