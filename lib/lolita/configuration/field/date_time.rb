module Lolita
  module Configuration
    module Field
      class DateTime < Lolita::Configuration::Field::Base
        attr_accessor :format
        def initialize *args
          @type="date_time"
          super
        end
      end
    end
  end
end
