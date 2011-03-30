module Lolita
  module Configuration
    class TextField < Lolita::Configuration::Field
      lolita_accessor :simple, :rows
      def initialize *args
        @type="text"
        super
      end
    end
  end
end