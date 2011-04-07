module Lolita
  module Configuration
    module Field
     
      class Time < Lolita::Configuration::Field::Base
        attr_accessor :format
        def initialize *args
          @type="time"
          super
        end

      end
      
    end
  end
end
