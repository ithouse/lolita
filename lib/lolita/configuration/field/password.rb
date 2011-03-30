module Lolita
  module Configuration
    class PasswordField < Lolita::Configuration::Field
      def initialize *args
        @type="password"
        super
      end
    end
  end
end