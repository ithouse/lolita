module Lolita
  module Configuration
    # Proxy class for search. It supports two methods #with and #run.
    # By default with method accepts method name or nothing and creates Lolita::Search::Simple instance
    # that will be used to run search on current dbi. 
    # #with method also accepts class or instance of some class, that will be used to run search.
    # That class should have #run method that accepts query and request. 
    # ====Example
    #     class MyCustomSearch
    #       def initialize(dbi)
    #         @dbi = dbi
    #       end
    #   
    #       def run(query,request = nil)
    #         @dbi.klass.where(:my_field => query)
    #       end
    #     end
    # Also you can put your search method in model. For more see Lolita::Search::Simple
    # ====Example
    #     class Post < ActiveRecord::Base
    #       lolita do
    #         list do
    #           search :my_custom_search
    #         end
    #       end
    #       
    #       def self.my_custom_search(query,request)
    #         self.where(:title => query, :user_id => request.params[:user_id])
    #       end
    #     end    
    class Search
      include Lolita::Builder
      attr_reader :dbi
      attr_writer :with

      def initialize dbi, *args, &block
        @dbi = dbi
        set_attributes(args ? args.extract_options! : {})
        instance_eval(&block) if block_given?
      end

      def with(value = nil)
        @with = value if value
        if !@with || [String,Symbol].include?(@with.class)
          @with = Lolita::Search::Simple.new(dbi,@with)
        elsif @with.class == Class
          @with = @with.new(dbi)
        end
        @with
      end

      def run(query,request = nil)
        self.with.run(query,request)
      end

      private

      def set_attributes options
        if options.respond_to?(:each)
          options.each do |method_name, value| 
            self.send(:"#{method_name}=",value)
          end
        end
      end

    end

  end
end