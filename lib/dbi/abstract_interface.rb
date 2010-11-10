
module Lolita
  module DBI
    class AbstractInterface

      attr_reader :dbi
      def initialize(dbi)
        @dbi=dbi
        self.class.class_eval do
          include "Adapter::#{dbi.source.to_s.camelize}"
        end
      end
    end
  end
end