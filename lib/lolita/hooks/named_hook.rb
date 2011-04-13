module Lolita
  module Hooks

    # Named hooks is special hook class that uses Lolita::Hooks, but also add some other useful methods and behaviour.
    # Main reason for named hooks is to provide filter like hooks. First thing is to define it for futher use.
    #    Lolita::Hooks::NamedHook.add(:people) 
    # Next step is to add hook for it. Like this
    #    Lolita::Hooks.people.add_hook(:get_married)
    # And then add callback for named hook.
    #    Lolita::Hooks.person.get_merried do
    #      go_to_honeymoon
    #    end
    #    john=Person.new("John")
    #    john.run(:get_merried) # and now john will go to honeymoon
    # Hooks are added for pluralized hook name, even if you pass like #add(:person), it will create named hook
    # with <i>people</i> name. This will be class, and when you call #person it will create instance for that class.
    class NamedHook

      class << self
        # Add named hook name with NamedHook class. Each hook is Hash and keys is filters. 
        # Also it have <em>:_class</em> key that is class for named hook.
        def add(name)
          name=name.to_s.pluralize
          named_hooks[name.to_sym]={:_class=>get_named_hook_class(name)}
          add_filter_method(name)
        end

        # All defined named hook names
        def names
          named_hooks.keys
        end

        # Detect that named hook exist with given name.
        def exist?(name)
          self.names.include?(name)
        end

        # Find or create named hook instance.
        def find_or_create(hook_name,filter_name)
          unless filtered_hook=self.find(hook_name,filter_name)
            named_hook=self.by_name(hook_name)
            named_hook[:_class].new(hook_name,filter_name)
          else
            filtered_hook
          end
        end

        # Find named hook filter.
        # ====Example
        #     Lolita::Hooks::NamedHook.find(:components,:"list")
        def find(hook_name,filter_name)
          if named_hook=self.by_name(hook_name)
            named_hook[filter_name.to_sym]
          end
        end

        # Return named hook by given name.
        def by_name(name)
          name=name.to_s.pluralize
          named_hooks[name.to_sym]
        end

        private

        def named_hooks
          @@named_hooks||={}
          @@named_hooks
        end

        def add_filter_method(name)
          self.class_eval <<-FILTER,__FILE__,__LINE__+1
            class << Lolita::Hooks
              def #{name.singularize}(name)
                Lolita::Hooks::NamedHook.find_or_create("#{name.pluralize}",name)
              end
            end
          FILTER
        end

        def get_named_hook_class(name)
          klass=Class.new(Lolita::Hooks::NamedHook)
          klass.instance_variable_set(:"@hook_name",name.to_sym)
          klass.send(:include,Lolita::Hooks)
          define_named_hook_class_methods(klass)
          klass
        end

        def define_named_hook_class_methods(klass)
          klass.class_eval do
            attr_accessor :name,:hook_name
            def initialize hook_name,name
              named_hook=self.class.by_name(hook_name)
              @name=name
              @hook_name=hook_name
              unless named_hook[name.to_sym]
                named_hook[name.to_sym]=self
              else
                raise ArgumentError, "Named hook #{name} for #{hook_name} already exist!"
              end
            end

            def self.hook_name
              @hook_name
            end

            # def self.run(*hook_names,&block)
            #   hook_names||=[]
            #   hook_names.extract_options!
            #   super(*hook_names,&block)
            #   if named_hook=self.by_name(self.hook_name)
            #     named_hook.each{|filter_name, filter|
            #       unless filter_name.to_sym==:"_class"
            #         self.run(*(hook_names + [{:scope=>filter}]),&block)
            #       end
            #     }
            #   end
            # end
            
          end
        end

      end

    end
  end
end