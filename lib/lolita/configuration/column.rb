module Lolita
  module Configuration
    class Column 
      
      attr_writer :name, :title, :type, :options
      
      def initialize(*args,&block)
        self.set_attributes(*args)
        self.instance_eval(&block) if block_given?
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

      def set_attributes(*args)
        if !args.empty?
          if args[0].is_a?(Hash)
            args[0].each{|m,value|
              self.send("#{m}=".to_sym,value)
            }
          elsif args[0].is_a?(Symbol) || args[0].is_a?(String)
            self.name=args[0].to_s
          else
            raise ArgumentError.new("Lolita::Configuration::Column arguments must be Hash or Symbol or String instead of #{args[0].class}")
          end
        end
      end
      
    end
  end
end
