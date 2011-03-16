module Lolita
  module Hooks
    module Hooks
      def self.included(base)
        base.extend(SingletonMethods)
      end

      module SingletonMethods
        def component(name)
       	  Lolita::Hooks::Component.get(name)
        end
      end
    end
  end
end