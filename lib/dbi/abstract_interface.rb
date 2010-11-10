
module Lolita
  module DBI
    class AbstractInterface

      attr_reader :dbi
      def initialize(dbi)
        @dbi=dbi
        self.class.class_eval do
          if dbi.source==:mongo
            include Connector::Mongoid
          elsif dbi.source==:mysql
            include Connector::ActiveRecord
          end
        end
      end
    end
  end
end