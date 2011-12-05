module Lolita
  module Configuration
    # Proxy class for search. It supports two methods #with and #run.
    # By default with method accepts method name or nothing and creates Lolita::Search::Simple instance
    # that will be used to run search on current dbi. 
    # By default search run against all content fields, but when _:fields_ options is passed it search in
    # those fields only. 
    # ==== Example
    #     class Post < ActiveRecord::Base
    #       include Lolita::Configuration
    #       lolita do
    #         list do
    #           search :fields => [:name]
    #         end
    #       end
    #     end
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
    #       include Lolita::Configuration
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
      attr_writer :with, :fields

      def initialize dbi, *args, &block
        @dbi = dbi
        set_attributes(args ? args.extract_options! : {})
        instance_eval(&block) if block_given?
        @with ||= args[0]!=true && args[0] ? args[0] : nil 
      end

      def with(value = nil)
        @with = value if value
        if !@with || [String,Symbol].include?(@with.class)
          @with = Lolita::Search::Simple.new(dbi,@with, :fields => @fields)
        elsif @with.class == Class
          initialize_arity = @with.instance_method(:initialize).arity
          @with = if initialize_arity < 0 || initialize_arity > 1
            @with.new(dbi,:fields => @fields)
          else
            @with.new(dbi)
          end
        end
        @with
      end

      def run(query,request = nil)
        if self.with.method(:run).arity < 0 || self.with.method(:run).arity > 1
          self.with.run(query,request)
        else
          self.with.run(query)
        end
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