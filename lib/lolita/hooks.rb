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

      def fire(*hook_names,&block)
        options=hook_names.extract_options!
        (hook_names || []).each do |hook_name|
          raise Lolita::HookNotFound, "Hook #{hook_name} is not defined for #{self}." unless self.has_hook?(hook_name)
          in_hooks_scope(options[:scope]) do
            callback=get_callback(hook_name)
            run_callback(callback,&block)
          end
        end
      end

      def has_hook?(name)
        self.hooks.include?(name.to_sym)
      end

      def method_missing(method_name, *args, &block)
        if method_name.to_s.match(/fire_(\w+)/)
          self.fire($1.to_sym,*args,&block)
        else
          super
        end
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

      def run_callback(callback,&block)
        run_methods(callback[:methods],&block)
        run_blocks(callback[:blocks],&block)
      end

      def run_methods methods, &block
        (methods||[]).each do |method_name|
          hooks_scope.send(method_name,&block)
        end
      end

      def run_blocks blocks,&given_block
        (blocks||[]).each do |block|
          if block_given?
            hooks_scope.instance_eval do
            block.call(&given_block)
          end
          else
            hooks_scope.instance_eval(&block)
          end
        end
      end

      def get_callback(name)
        scope_callbacks=hooks_scope.callbacks[name.to_sym] || {}
        unless hooks_scope==self
          class_callbacks=self.callbacks[name.to_sym] || {}
          [:methods,:blocks].each do |attr|
            scope_callbacks[attr]=((scope_callbacks[attr] || [])+(class_callbacks[attr] || [])).uniq
          end
        end
        scope_callbacks
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

      def method_missing(method_name,*args,&block)
        if method_name.to_s.match(/fire_(\w+)/)
          self.class.fire($1.to_sym,*args,&block)
        else
          super
        end
      end
    end

  end
end