module Lolita
  module RouteHack
    
    def self.included(base)
      base.class_eval{
        include InstanceMethods
      }
      base.alias_method_chain :load_routes!, :lolita
    end

    module InstanceMethods
      def load_routes_with_lolita!
        lolita_routes = File.join(File.dirname(__FILE__), *%w[.. .. config lolita_routes.rb])
        unless configuration_files.include? lolita_routes
          add_configuration_file(lolita_routes)
        end
        project_routes_tail = File.join(RAILS_ROOT, *%w[config routes_tail.rb])
        if File.exists?(project_routes_tail) && ! configuration_files.include?(project_routes_tail)
          add_configuration_file(project_routes_tail)
        end
        load_routes_without_lolita!
      end

    end

  end
end