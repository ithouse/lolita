require 'haml'
require 'action_controller/railtie'

Lolita.default_route = :rest

require 'lolita/rails/routes'

module ActionDispatch::Routing
  class Mapper
    protected
    def lolita_rest_route mapping, controllers
      resources mapping.plural,:only=>mapping.only.is_a?(Array) ? mapping.only : [:index,:new,:create,:edit,:update,:destroy],
        :controller=>controllers[:rest],:module=>mapping.module
    end
  end
end