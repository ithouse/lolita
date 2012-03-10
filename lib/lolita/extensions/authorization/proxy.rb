module Lolita
  module Extensions
    module Authorization

      class Proxy
        def initialize context,options={}
          @adapter = Object.new
        end

        def can? *args
        end

        def cannot? *args
        end

        def authorize! *args
        end

        def current_ability *args
        end
        
      end

    end
  end
end