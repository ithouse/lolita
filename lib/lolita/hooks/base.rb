module Lolita
  module Hooks
    class Base
        
      class << self
        def get(name)
          @collection||={}
          @collection[name]||=self.new(name)
          @collection[name]
        end

        def define_callback *names
          names.each do |name|
              self.class_eval <<-CALLBACK,__FILE__,__LINE__+1
                def #{name}(*args,&block)
                  @callbacks||={}
                  @callbacs[:#{name}]||={}
                  @callbacks[:#{name}][:methods]=args || []
                  @callbacks[:#{name}][:block]=block if block_given?
                end

                def run_#{name} scope, &block
                  self.run(scope,:"#{name}",&block)
                end
              CALLBACK
          end
        end
      end

      # To wrap around some content, for example, html code, 
      # call run with block.
      # ====Example
      #     # in other view
      #     Lolita::Hooks.component(:"lolita/list").replace_with do
      #       # my new html code
      #     end
      #     # in view
      #     Lolita::Hooks.component(:"lolita/list").run(self,:replace_with) do
      #       # your old html here
      #     end
      #     # After this old code will be replaced with new one
      def run scope,name, &block
        @callbacks[name][:methods].each do |m|
          scope.send(m)
        end
        if @callbacks[name][:block]
          if block_given?
            callback[name][:block].call()
          else
            scope.instance_eval(&callbacks[name][:block])
          end
        end
        @callbacks[name]={}
      end

    end
  end
end