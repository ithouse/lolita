module Lolita
  module Configuration
    class Column

      attr_writer :name, :title, :type, :options
      
      def initialize(*args,&block)
        block_given? ? self.instance_eval(&block) : self.generate(*args)
        raise ArgumentError.new("Column must have name.") unless self.name
      end

      def name(value=nil)
        self.name=value if value
        @name
      end

      def title(value=nil)
        self.title=value if value
        @title
      end

      def type(value=nil)
        self.type=value if value
        @type
      end

      def generate(*args)
        if !args.empty?
          if args[0].is_a?(Hash)
            args[0].each{|m,value|
              self.send("#{m}=".to_sym,value)
            }
          else
            raise ArgumentError.new("Lolita::Configuration::Column arguments must be Hash instead of #{args[0].class}")
          end
        end
      end
      
    end
  end
end
