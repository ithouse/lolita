module Lolita
  module Routing
    module MapperExtensions
      def lolita
        @set.add_route  'admin',  :controller=>'admin/configuration', :action=>'list', :path_prefix => '/:locale'
        @set.add_route  'system/login',   :controller=>'admin/user',  :action=>'login', :path_prefix => '/:locale'
        @set.add_route  'system/logout',  :controller=>'admin/user ', :action=>'logout', :path_prefix => '/:locale'
      end
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send :include, Lolita::Routing::MapperExtensions