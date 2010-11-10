
module Lolita
  module DBI
    module AbstractInterface

      attr_reader :dbi
      def connect_adapter(dbi)
        @dbi=dbi
        self.class.class_eval do
          include "Adapter::#{dbi.source.to_s.camelize}".constantize
        end
      end
    end
  end
end