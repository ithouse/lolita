module Lolita
  module Configuration
    module Field
      class Datetime < Lolita::Configuration::Field::Base
        attr_accessor :format
        def initialize *args
          @type="date"
          super
        end
      end
    end
  end
end