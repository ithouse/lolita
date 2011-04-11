module Lolita
  module Hooks
    def self.included(base)
      base.extend(ClassMethods)
      base.extend(CommonMethods)
      base.class_eval{
        include CommonMethods
        include InstanceMethods
      }
    end

    module CommonMethods
      
      def callbacks
        var=self.instance_variable_get(:@callbacks)
        unless var
          var={}
          self.instance_variable_set(:@callbacks,var)
        end
        instance_variable_get(:@callbacks)
      end
    end

    module ClassMethods

      def hooks_scope=(object)
        @hooks_scope=object
      end

      def hooks_scope
        @hooks_scope||self
      end

      def hooks
        @hooks||=[]
        @hooks
      end


      def clear_hooks
        @hooks=[]
        @callbacks={}
      end

      def add_hook(*names) 
        (names||[]).each{|hook_name|
          self.class_eval <<-HOOK,__FILE__,__LINE__+1
            def self.#{hook_name}(*methods,&block)
              options=methods.extract_options!
              in_hooks_scope(options[:scope]) do
                register_callback(:"#{hook_name}",*methods,&block)
              end
            end

            def #{hook_name}(*method,&block)
              self.class.#{hook_name}(*method,:scope=>self,&block)
            end
          HOOK
          register_hook(hook_name)
        }
      end

      def fire(*hook_names)
        options=hook_names.extract_options!
        in_hooks_scope(options[:scope]) do
          (hook_names || []).each do |hook_name|
            raise Lolita::HookNotFound, "Hook #{hook_name} is not defined for #{self}." unless self.has_hook?(hook_name)
            callback=get_callback(hook_name)
            run_callback(callback)
          end
        end
      end

      def has_hook?(name)
        self.hooks.include?(name.to_sym)
      end

      protected

      def in_hooks_scope(scope)
        begin
          self.hooks_scope=scope||self
          yield
        ensure
          self.hooks_scope=self
        end
      end

      def run_callback(callback)
        run_methods(callback[:methods])
        run_blocks(callback[:blocks])
      end

      def run_methods methods
        (methods||[]).each do |method_name|
          hooks_scope.send(method_name,true)
        end
      end

      def run_blocks blocks
        (blocks||[]).each do |block|
          hooks_scope.instance_eval(&block)
        end
      end

      def get_callback(name)
        hooks_scope.callbacks[name.to_sym] || {}
      end

      def register_callback(name,*methods,&block)
        temp_callback=hooks_scope.callbacks[name]||{}
        temp_callback[:methods]||=[]
        temp_callback[:methods]+=(methods||[]).compact
        temp_callback[:blocks]||=[]
        temp_callback[:blocks]<< block if block_given?
        hooks_scope.callbacks[name]=temp_callback
      end

      def register_hook(name)
        self.hooks<<name
      end
    end

    module InstanceMethods

      def fire(*hook_names)
        self.class.fire(*hook_names,:scope=>self)
      end
    end

  end
end