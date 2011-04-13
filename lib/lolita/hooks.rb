module Lolita
  # Provide hook mechanism for Lolita. To use hooks for class start with including this in your own class.
  # Next step is hook definition. This may be done using Lolita::Hooks#add_hook method.
  # Hooks are stored in class <i>@hooks</i> variable, that is Hash and each key is hook name
  # and each hook also is Hash that have <em>:methods</em> and <em>:blocks</em>
  # keys. Both of those are Array, and each time you call callback method, like <i>before_save</i> and so on, block 
  # and/or methods is stored. <b>Each time</b> #run is called all blocks and methods will be executed.
  # It may look like this.
  #    class MyClass
  #      include Lolita::Hooks
  #      add_hook :before_save, :after_save
  #    end
  #    # This will define two hooks for MyClass.
  # To add hook callback just call hook name on class and pass method(-s) or block.
  #    MyClass.after_save :write_log
  #    MyClass.before_save do
  #      validate(self)
  #    end
  # ==Scopes
  # Most times hook callbacks are defined for class like in previous example, but also it's possible to do it
  # on class instances. Difference between calling it on class or on instance is that instance callbacks will
  # be called only when event is runned on instance. Class callbacks will be called on class and also on instance
  # callbacks.
  #    my_object=MyClass.new
  #    MyClass.before_save do
  #      puts "class callback"
  #    end
  #    my_object.before_save do
  #      puts "instance callback"
  #    end
  #    
  #    MyClass.run(:before_save) #=> 
  #      class_callback
  #    
  #    my_object.run(:before_save) #=>
  #      class_callback
  #      instance_callback
  #   # As you can see, first class callbacks is called and after that instance callbacks.
  #
  # ==Firing events
  # To execute callbacks, events should be called on object. Event names is same hooks names. #run can be called
  # on class or on instance. Also it is possible to pass block to run event, that will replace callback block
  # or if #let_content is called than it will work like wrapper, like this
  #    # this is continuation of previous code
  #    MyClass.run(:before_save) do
  #      puts "replaced text"
  #    end
  #    # will produce #=> replaced text
  #    
  #    MyClass.run(:before_save) do
  #      puts "before callback"
  #      let_content
  #      puts "after callback"
  #    end
  #    # this will produce #=>
  #    #  before callback
  #    #  class callback
  #    #  after callback
  # ==Named hooks
  # See Lolita::Hooks::NamedHook for details.
  module Hooks
    def self.included(base)
      base.extend(ClassMethods)
      base.extend(CommonMethods)
      base.class_eval{
        include CommonMethods
        include InstanceMethods
      }
    end

    # Look for named hook with singular or plural name of method.
    def self.method_missing method_name,*args, &block
      if named_hook=(Lolita::Hooks::NamedHook.by_name(method_name))
        named_hook[:_class]
      else 
        super
      end
    end

    # Shared methods between class and instance.
    module CommonMethods
      
      # All callbacks for class or instance.
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

      # Setter for #hook_scope.
      def hooks_scope=(object)
        @hooks_scope=object
      end

      # Hooks scope is used to execute callbacks. By default it is class itself.
      def hooks_scope
        @hooks_scope||self
      end

      # Setter for #callback_content
      def given_callback_content=(content)
        @given_callback_content=content
      end

      # Callback content is used to let callback content executed insede of run block.
      def given_callback_content
        @given_callback_content
      end

      # All hooks for class. This is Array of hook names.
      def hooks
        @hooks||=[]
        @hooks
      end

      # Reset all hooks and callbacks to defaults.
      def clear_hooks
        @hooks=[]
        @callbacks={}
      end

      # This method is used to add hooks for class. It accept one or more hook names.
      # ====Example
      #     add_hook :before_save
      #     MyClass.add_hooks :after_save, :around_save
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

      # run is used to execute callback. Method accept one or more <i>hook_names</i> and optional block.
      # It will raise error if hook don't exist for this class. Also it accept <em>:scope</em> options, that
      # is used to #get_callbacks and #run_callbacks.
      # ====Example
      #     MyClass.run(:before_save,:after_save,:scope=>MyClass.new)
      #     # this will call callbacks in MyClass instance scope, that means that self will be MyClass instance.
      def run(*hook_names,&block)
        options=hook_names.extract_options!
        (hook_names || []).each do |hook_name|
          raise Lolita::HookNotFound, "Hook #{hook_name} is not defined for #{self}." unless self.has_hook?(hook_name)
          in_hooks_scope(options[:scope]) do
            callback=get_callback(hook_name)
            run_callback(callback,&block)
          end
        end
      end

      # Is hook with <em>name</em> is defined for class.
      def has_hook?(name)
        self.hooks.include?(name.to_sym)
      end

      # Try to recognize named run methods like 
      #    MyClass.run_after_save # will call MyClass.run(:after_save) 
      def method_missing(*args, &block)
        unless self.recognize_hook_methods(*args,&block)
          super
        end
      end

      # Call callback block inside of run block.
      # ====Example
      #     MyClass.run(:before_save) do 
      #        do_stuff
      #        let_content # execute callback block(-s) in same scope as run is executed.
      #     end
      def let_content
        if content=self.given_callback_content
          run_block(self.given_callback_content)
        end
      end

      # Set #method_missing
      def recognize_hook_methods method_name, *args, &block
        if method_name.to_s.match(/^run_(\w+)/)
          self.run($1,*args,&block)
          true
        end
      end

      protected

      # Switch between self and given <em>scope</em>. Block will be executed with <em>scope</em>.
      # And after that it will switch back to self.
      def in_hooks_scope(scope)
        begin
          self.hooks_scope=scope||self
          yield
        ensure
          self.hooks_scope=self
        end
      end

      # Run callback. Each callback is Hash with <i>:methods</i> Array and </i>:blocks</i> Array
      def run_callback(callback,&block)
        run_methods(callback[:methods],&block)
        run_blocks(callback[:blocks],&block)
      end

      # Run methods from <em>methods</em> Array
      def run_methods methods, &block
        (methods||[]).each do |method_name|
          hooks_scope.__send__(method_name,&block)
        end
      end

      # Run blocks from <em>blocks</em> Array. Also it set #given_callback_content if block is given, this
      # will allow to call #let_content. Each block is runned with #run_block.
      def run_blocks blocks,&given_block
        (blocks||[]).each do |block|
          begin
            if block_given?
              self.given_callback_content=given_block
            end
            run_block(block,&given_block)
          ensure
            self.given_callback_content=nil
          end
        end
      end

      # Run block in scope. 
      def run_block block, &given_block
        hooks_scope.instance_eval(&block)
      end

      # Return all callbacks
      # If scope is not class then it merge class callbacks with scope callbacks. That means that
      # class callbacks always will be called before scope callbacks.
      def get_callback(name)
        scope_callbacks=hooks_scope.callbacks[name.to_sym] || {}
        unless hooks_scope==self
          class_callbacks=self.callbacks[name.to_sym] || {}
          [:methods,:blocks].each do |attr|
            scope_callbacks[attr]=((class_callbacks[attr] || [])+(scope_callbacks[attr] || [])).uniq
          end
        end
        scope_callbacks
      end

      # Register callback with given scope.
      def register_callback(name,*methods,&block)
        temp_callback=hooks_scope.callbacks[name]||{}
        temp_callback[:methods]||=[]
        temp_callback[:methods]+=(methods||[]).compact
        temp_callback[:blocks]||=[]
        temp_callback[:blocks]<< block if block_given?
        hooks_scope.callbacks[name]=temp_callback
      end

      # Register hook for scope.
      def register_hook(name)
        self.hooks<<name
      end
    end

    # Methods for instance.
    module InstanceMethods

      # See Lolita::Hooks::ClassMethods#run
      def run(*hook_names)
        self.class.run(*hook_names,:scope=>self)
      end

      # See Lolita::Hooks::ClassMethods#let_content
      def let_content
        self.class.let_content
      end

      # See Lolita::Hooks::ClassMethods#method_missing
      def method_missing(*args,&block)
        unless self.class.recognize_hook_methods(*args,:scope=>self,&block)
          super
        end
      end
    end

  end
end