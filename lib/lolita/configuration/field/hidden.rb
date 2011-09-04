module Lolita
  module Configuration
    module Field
      class Hidden < Lolita::Configuration::Field::Base
        def initialize dbi,name,type,options, &block
          
          super
        end
      end
    end
  end
end
