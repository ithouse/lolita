module Lolita
  module Extensions
    module Authorization
      
      class DefaultAdapter
        
        def initialize *args
        end
        
        def can? *args
          true
        end

        def cannot? *args
          false
        end

        def current_ability *args
        end

        def authorize! *args
          true
        end

      end

    end
  end
end