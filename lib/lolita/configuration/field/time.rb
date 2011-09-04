module Lolita
  module Configuration
    module Field
      class Time < Lolita::Configuration::Field::Base
        attr_accessor :format
        def initialize dbi,name,*args, &block
         
          super
        end
      end
    end
  end
end
