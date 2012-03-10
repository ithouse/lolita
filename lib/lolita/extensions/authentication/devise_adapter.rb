module Lolita
  module Extensions
    module Authentication
      
      class DeviseAdapter
        def initialize context, options={}
          raise Lolita::NoAuthenticationDefinedError, "Lolita.authentication is not defined" unless Lolita.authentication
          @context = context
        end

        def current_user
          unless @current_user
            find_class_and_user do |klass,user|
              @current_user = user
            end
          end
          @current_user
        end
        
        def user_signed_in?
          !!current_user
        end

        def authenticate_user!
          if @context.is_a?(::ActionController::Base)
            @context.send(Lolita.authentication)
          end
        end

        def sign_out_via
          ::Devise.sign_out_via
        end
        
        def edit_path
          find_class_and_user do |klass,user|
            return @context.send(:"edit_#{klass.to_s.downcase}_password_path")
          end
        end

        def sign_out_path
          find_class_and_user do |klass,user|
            return @context.send(:"destroy_#{klass.to_s.downcase}_session_path")
          end
        end

        private

        def find_class_and_user
          Lolita.user_classes.each do |klass|
            if @context.respond_to?(:"current_#{klass.to_s.downcase}") && user = @context.send(:"current_#{klass.to_s.downcase}")
              yield klass, user
              break
            end
          end
        end
      end

    end
  end
end