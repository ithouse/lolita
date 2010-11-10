module Lolita
  module Configuration
    class Tab

      def initialize(*args,&block)
        build(*args)
        self.instance_eval(&block) if block_given?
      end

      def fields
        puts "tab fields"
      end
      
      private
      def build(options={})
        puts "build"
      end
    end
  end
end