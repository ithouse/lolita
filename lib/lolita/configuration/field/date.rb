module Lolita
  module Configuration
    module Field
      class Datetime < Lolita::Configuration::Field::Base
        attr_accessor :format
        def initialize *args
          @type="datetime"
          super
        end
      end
    end
  end
end