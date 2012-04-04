module Lolita
  module Components
    
    class Base
      attr_reader :parent
      def initialize(parent)
        @parent = parent
      end
    end

  end
end