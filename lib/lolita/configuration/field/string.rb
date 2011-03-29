module Lolita
  module Configuration
    class StringField < Lolita::Configuration::Field

      def initialize *args, &block
        @type="string"
        super
      end
    end
  end
end