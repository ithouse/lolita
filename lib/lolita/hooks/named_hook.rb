module Lolita
  module Hooks

    class NamedHook
      include Lolita::Hooks

      class << self
        def add(name)
          @names||={}
          name=name.to_s.pluralize
          @names[name.to_sym]={}
          add_filter_method(name)
        end

        def add_filter_method(name)
          self.class_eval <<-FILTER,__FILE__,__LINE__+1
            class << Lolita::Hooks
              def #{name.singularize}(name)
                Lolita::Hooks::NamedHook.find_or_create("#{name.singularize}",name)
              end
            end
          FILTER
        end

        def find_or_create(hook_name,filter_name)
          if named_hook=self.by_name(hook_name)
            if filtered_hook=named_hook[filter_name.to_sym]
              filtered_hook
            else
              self.new(hook_name,filter_name)
            end
          end
        end

        def by_name(name)
          name=name.to_s.pluralize
          @names[name.to_sym]
        end
      end

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

    end
  end
end