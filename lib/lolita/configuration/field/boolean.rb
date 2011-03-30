module Lolita
  module Configuration
    class BooleanField < Lolita::Configuration::Field
      def initialize *args
        @type="boolean"
        super
      end
    end
  end
end