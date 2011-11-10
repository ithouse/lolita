module Lolita
  module Search

    # Default search class for Lolita::Search. Lolita::Configuration::Search uses this by default.
    # It accepts method name as constructor argument, when none is given it call Lolita::DBI#search.
    class Simple

      # Method in model used to run a search.
      attr_accessor :search_method
      attr_reader :dbi

      # Accepts search method as optional argument
      def initialize(dbi, search_method = nil)
        @dbi = dbi
        @search_method = search_method
      end

      # Require dbi (Lolita::DBI instance), query (String) and request as optional argument.
      # When there is search method defined, it uses that otherwise run default search.
      def run(query,request=nil,dbi=nil)
        with_query(query,request,dbi) do
          if self.search_method
            run_custom_search
          else
            run_default_search
          end
        end
      end

      private

      def with_query(query,request,dbi)
        begin
          @old_dbi = self.dbi
          @dbi = dbi if dbi
          @query = query
          @request = request
          yield
        ensure
          @dbi = @old_dbi
          @query,@request = nil,nil
        end
      end

      def run_custom_search
        @dbi.klass.send(self.search_method.to_sym,@query,@request)
      end

      def run_default_search
        @dbi.search(@query)
      end
    end

  end
end