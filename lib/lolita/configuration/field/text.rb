module Lolita
  module Configuration
    class TextField < Lolita::Configuration::Field
      def initialize *args
        @type="text"
        super
      end
    end
  end
end