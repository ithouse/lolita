module Lolita
  module Configuration
    class DisabledField < Lolita::Configuration::Field
      def initialize *args
        @type="disabled"
        super
      end
    end
  end
end