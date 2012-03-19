module Lolita
  module Extensions
    module Authorization
      
      class CanCanAdapter
        
        def initialize context, options={}
          raise NameError, "CanCan is not defined" unless defined?(CanCan)
          raise Lolita::NoAuthorizationDefinedError, "Lolita.authorization is not defined" unless Lolita.authorization
          @context = context
          @options = options
          set_default_options
          current_ability
        end

        def can? *args
          current_ability.can?(*args)
        end

        def cannot? *args
          current_ability.cannot?(*args)
        end

        def current_ability *args
          unless @current_ability 
            @current_ability = Lolita.ability_class.new(@options[:current_user])
            @context && @context.instance_variable_set(:"@current_ability",@current_ability)
          end
          @current_ability
        end

        def authorize! *args
          current_ability && @context && @context.authorize!(*args) || current_ability.authorize!(*args)
        end
        
        private

        def set_default_options
          @options[:current_user] ||= @context && @context.authentication_proxy.current_user
        end
      end

    end
  end
end