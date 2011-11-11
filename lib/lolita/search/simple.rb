module Lolita
  module Search

    # Default search class for Lolita::Search. Lolita::Configuration::Search uses this by default.
    # It accepts method name as constructor argument, when none is given it call Lolita::DBI#search.
    class Simple

      # Method in model used to run a search.
      attr_accessor :search_method
      attr_reader :dbi

      # Accepts search method as optional argument
      def initialize(dbi, *args)
        @dbi = dbi
        @options = args.extract_options!
        @search_method = args[0]
      end

      # Require dbi (Lolita::DBI instance), query (String) and request and dbi as optional argument.
      # Also you can pass options.
      # ====Example
      #     search.run("query",:fields => [:name])
      #     # this will search only in :name field
      #     search.run("query",nil, Lolita::DBI::Base.create(Category))
      #     # this will use Category dbi for search
      # When there is search method defined, it uses that otherwise run default search.
      def run(query,*args)
        with_query(query,*args) do
          if self.search_method
            run_custom_search
          else
            run_default_search
          end
        end
      end

      private

      def with_query(query,*args)
        begin
          options = args.extract_options!
          @old_dbi = self.dbi
          @old_options = @options 
          @options = options if options.any?
          @dbi = args[1] if args[1]
          @query = query
          @request = args[0]
          yield
        ensure
          @dbi = @old_dbi
          @options = @old_options
          @query,@request = nil,nil
        end
      end

      def run_custom_search
        search_method_arity = @dbi.klass.method(self.search_method).arity
        args = [@query,@request,@options]
        if search_method_arity < 0
          @dbi.klass.send(self.search_method.to_sym,@query,@request,@options)
        elsif search_method_arity == 0
          raise ArgumentError, "#{@dbi.klass.to_s} method #{search_method} must accept at least 1 argument."
        else
          arity_limit = search_method_arity > args.size ? args.size : search_method_arity
          @dbi.klass.send(self.search_method.to_sym,*(args.slice(0..(arity_limit-1))))
        end
        @dbi.klass.send(self.search_method.to_sym,@query,@request)
      end

      def run_default_search
        @dbi.search(@query,@options || {})
      end
    end

  end
end