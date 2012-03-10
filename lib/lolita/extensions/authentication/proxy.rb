require "#{File.dirname(__FILE__)}/default_adapter"
require "#{File.dirname(__FILE__)}/devise_adapter"

module Lolita
  module Extensions
    module Authentication

      class Proxy
        attr_accessor :adapter

        def initialize context,options={}
          @context = context
          @options = options
          @adapter = get_adapter()
        end

        def current_user
          @adapter.current_user
        end
        
        def user_signed_in?
          @adapter.user_signed_in?
        end
        
        def authenticate_user!
          @adapter.authenticate_user!
        end

        def sign_out_via
          @adapter.sign_out_via unless default_adapter?
        end
        
        def edit_path
          # send(:"edit_#{authentication_proxy.current_user.class.to_s.downcase}_password_path")
          @adapter.edit_path unless default_adapter?
        end

        def sign_out_path
          # send(:"destroy_#{authentication_proxy.current_user.class.to_s.downcase}_session_path")
          @adapter.sign_out_path unless default_adapter?
        end

        def default_adapter?
          self.adapter.is_a?(Lolita::Extensions::Authentication::DefaultAdapter)
        end

        private

        def get_adapter
          if Lolita.authentication
            Lolita::Extensions::Authentication::DeviseAdapter.new @context, @options
          else
            Lolita::Extensions::Authentication::DefaultAdapter.new @context, @options
          end
        end
      end

    end
  end
end