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
    #    john.fire(:get_merried) # and now john will go to honeymoon
    # Hooks are added for pluralized hook name, even if you pass like #add(:person), it will create named hook
    # with <i>people</i> name. This will be class, and when you call #person it will create instance for that class.
    class NamedHook

      class << self
        # Add named hook name with NamedHook class. Each hook is Hash and keys is filters. 
        # Also it have <em>:_class</em> key that is class for named hook.
        def add(name)
          @names||={}
          name=name.to_s.pluralize
          @names[name.to_sym]={:_class=>get_named_hook_class()}
          add_filter_method(name)
        end

        # Find or create named hook instance.
        def find_or_create(hook_name,filter_name)
          if named_hook=self.by_name(hook_name)
            if filtered_hook=named_hook[filter_name.to_sym]
              filtered_hook
            else
              named_hook[:_class].new(hook_name,filter_name)
            end
          end
        end

        # Return named hook by given name.
        def by_name(name)
          name=name.to_s.pluralize
          @names[name.to_sym]
        end

        private

        def add_filter_method(name)
        self.class_eval <<-FILTER,__FILE__,__LINE__+1
          class << Lolita::Hooks
            def #{name.singularize}(name)
              Lolita::Hooks::NamedHook.find_or_create("#{name.singularize}",name)
            end
          end
        FILTER
        end

        def get_named_hook_class
          klass=Class.new
          klass.send(:include,Lolita::Hooks)
          klass.class_eval do
            attr_accessor :name,:hook_name
            def initialize hook_name,name
              named_hook=Lolita::Hooks::NamedHook.by_name(hook_name)
              @name=name
              @hook_name=hook_name
              unless named_hook[name.to_sym]
                named_hook[name.to_sym]=self
              else
                raise ArgumentError, "Named hook #{name} for #{hook_name} already exist!"
              end
            end
          end
          klass
        end

      end

    end
  end
end