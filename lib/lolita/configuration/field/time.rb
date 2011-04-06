module Lolita
  module Configuration
    class TimeField < Lolita::Configuration::Field
      attr_accessor :format
      def initialize *args
        @type="time"
        super
      end
    end
  end
end