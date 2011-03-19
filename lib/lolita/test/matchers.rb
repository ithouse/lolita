module Lolita
  module Test
    # Matchers that make easier to test Lolita and Lolita addons
    module Matchers

      class BeRoutable
      
        def matches?(actual)
          @actual=actual
          collect_routes
          set_method_and_url
          result=@routes.detect{|route| 
            method_match(route) && @url.to_s.match(route[:path_info])
          }
          !!result
        end

        def failure_message
          "expected #{@url.inspect}#{@method ? " with method #{@method.inspect}" : ""} to be routable"
        end
        def negative_failure_message
          "expected #{@url.inspect}#{@method ? " with method #{@method.inspect}" : ""}  to not be routable"
        end

        private

        def method_match(route)
          if route[:request_method]
            if @method
              @method.to_s.upcase.match(route[:request_method])
            else
              false
            end
          else
            true
          end
        end

        def set_method_and_url
          if @actual.is_a?(Hash)
            @method,@url=@actual.keys.first,@actual.values.first
          elsif @actual.is_a?(Array)
            if @actual.size>=2
              @method,@url=@actual[0],@actual[1]
            elsif
              @url=@actual.first
            end
          else
            @url=@actual.to_s
          end
        end

        def collect_routes
          @routes=[]
          all_applications.each do |application|
            @routes+=application.routes.routes.map(&:conditions)
          end
        end

        def all_applications
          if defined?(Rails) && defined?(Rails::Application)
            ObjectSpace.each_object(Rails::Application).select { |klass|
             klass.class < Rails::Application 
            }.map(&:class)
          else
            []
          end
        end
      end

       def be_routable
        BeRoutable.new
      end
    end
  end
end

