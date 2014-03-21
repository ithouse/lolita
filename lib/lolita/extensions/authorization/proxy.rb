require "#{File.dirname(__FILE__)}/default_adapter"
require "#{File.dirname(__FILE__)}/cancan_adapter"
require "#{File.dirname(__FILE__)}/pundit_adapter"

module Lolita
  class NoAuthorizationDefinedError < ArgumentError ; end

  module Extensions
    module Authorization

      class Proxy
        attr_accessor :adapter

        def initialize context,options={}
          @context = context
          @options = options
          @adapter = get_adapter()
        end

        def can? *args
          @adapter.can? *args
        end

        def cannot? *args
          @adapter.cannot? *args
        end

        def authorize! *args
          @adapter.authorize! *args
        end

        def current_ability *args
          @adapter.current_ability *args
        end

        private

        def get_adapter
          if Lolita.authorization
            "Lolita::Extensions::Authorization::#{Lolita.authorization}Adapter".constantize.new @context, @options
          else
            Lolita::Extensions::Authorization::DefaultAdapter.new @context, @options
          end
        end
      end

    end
  end
end
