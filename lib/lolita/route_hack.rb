module Lolita
  # RouteHack allows to append lolita's routes after the routes of the project using lolita
  #
  # Lolita's routes can be found in lolita/config/lolita_routes.rb,
  # if any routes need to be appended after lolita's routes you can do so by adding
  # RAILS_ROOT/config/routes_tail.rb file with all the content required for any routes.rb
  module RouteHack #:doc:
    
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