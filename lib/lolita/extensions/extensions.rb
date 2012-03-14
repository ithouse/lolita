module Lolita
  module Extensions
    EXTENSIONS = []
    
    def method_missing method_name, *args, &block
      if method_name[/_proxy$/]
        type = method_name.to_s.sub(/_proxy$/,"")
        self.class_eval <<-EXTENSION,__FILE__,__LINE__+1
          def #{method_name}(*args,&block)
            unless __extensions_proxies[:#{type}]
              load_extension_proxy(:#{type},self,__proxy_options_from_context)
            end
            __extensions_proxies[:#{type}]
          end
        EXTENSION
        send(method_name)
      else
        super
      end
    end

    def load_extensions_proxies(context=self, options={})
      EXTENSIONS.each do |type|
        load_extension_proxy(type,context,options)
      end
    end
    
    def load_extension_proxy type,context=self,options={}
      proxy_class = "Lolita::Extensions::#{type.to_s.camelize}::Proxy".constantize
      initialize_arity = proxy_class.instance_method(:initialize).arity
      __extensions_proxies[type] = if initialize_arity < 0 || initialize_arity > 1
        proxy_class.new(context,options)
      elsif initialize_arity == 0
        proxy_class.new
      else
        proxy_class.new(context)
      end
    end

    def self.add type
      EXTENSIONS << type unless EXTENSIONS.include?(type)
    end

    private

    def __proxy_options_from_context
      if defined?(::ActionController) && self.is_a?(::ActionController::Base)
        {:controller => self, :request => request}
      elsif defined?(::ActionView) && self.is_a?(::ActionView::Base)
        {:request => request}
      end
    end

    def __extensions_proxies 
      @proxies ||= {}
    end

  end
end

Lolita::Extensions.add :authentication
Lolita::Extensions.add :authorization

require 'lolita/extensions/authorization/proxy'
require 'lolita/extensions/authentication/proxy'