module Lolita
  module Configuration
    class IntegerField < Lolita::Configuration::Field
      def initialize *args
        @type="integer"
        super
      end
    end
  end
end