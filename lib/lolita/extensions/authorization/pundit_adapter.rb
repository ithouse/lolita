module Lolita
  module Extensions
    module Authorization
      class PunditAdapter

        def initialize context, options={}
          raise NameError, "Pundit is not defined" unless defined?(Pundit)
          raise Lolita::NoAuthorizationDefinedError, "Lolita.authorization is not defined" unless Lolita.authorization
          @context = context
          @options = options
          current_ability
        end

        def can? *args
          !!(ability = current_ability(*args) and ability.send(policy_method(args)))
        end

        def cannot? *args
          !can?(*args)
        end

        def current_ability *args
          if current_user && record = get_record(*args)
            @current_ability = Pundit.policy(current_user, record) || Lolita.policy_class.new(current_user, record)
            @context && @context.instance_variable_set(:"@current_ability", @current_ability)
          end
          @current_ability
        end

        def authorize! *args
          unless ability = current_ability(*args) and ability.public_send(policy_method(args))
            raise Pundit::NotAuthorizedError.new("not allowed to #{args.first} this #{args.last}")
          end
          true
        end

        private

        def current_user
          @context && @context.authentication_proxy.current_user
        end

        def get_record *args
          if args.any?
            record_as_instance(args.last)
          else
            mapping = @options[:request].env["lolita.mapping"] and mapping.class_name.constantize
          end
        end

        def policy_method args
          "#{args.first}?"
        end

        # pundit can receive only instance as record, but Lolita can give
        # sometime instance sometimes class or module, so we try to make it 
        # as instance
        def record_as_instance record
          if is_instance?(record)
            record
          elsif is_module?(record)
            record.to_s.to_sym
          else
            record.new
          end
        end

        def is_module? obj
          obj.class == Module
        end
        def is_instance? obj
          !obj.respond_to? :ancestors
        end
      end
    end
  end
end
