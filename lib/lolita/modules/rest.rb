module ActionDispatch::Routing
  class Mapper
    protected
    def lolita_rest mapping, controllers
      resources mapping.plural,:only=>[:index,:new,:create,:edit,:update,:destroy],
        :controller=>controllers[:rest],:module=>mapping.module
    end
  end
end

