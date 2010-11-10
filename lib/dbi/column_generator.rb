module Lolita
  module DBI
    class ColumnGenerator
      include Lolita::DBI::AbstractInterface

      def initialize(dbi)
        connect_adapter(dbi)
      end
    end
  end
end