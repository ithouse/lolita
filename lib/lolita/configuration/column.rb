module Lolita
  module Configuration
    class Column 

      MAX_TEXT_SIZE=20
      lolita_accessor :name,:title,:type,:options,:format
      
      def initialize(*args,&block)
        self.set_attributes(*args)
        self.instance_eval(&block) if block_given?
        validate
        set_default_values
      end
      
      #
      #  column do
      #    name "UID"
      #    format do(values)
      #      values.first+values.last
      #    end
      #  end
      # <%= column.with_format([@post.id,@post.user_id])%>
      def with_format(value) #TODO test
        if @format.respond_to?(:call)
          @format.call(value)
        elsif @format && (value.is_a?(Time) || value.is_a?(Date))
          format_for_datetime(value)
        else
          format_from_type(value)
        end
      end

      def format_from_type(value) #TODO test
        if value
          if value.is_a?(String)
            value
          elsif value.is_a?(Integer)
            value
          elsif value.is_a?(Date)
            if defined?(I18n)
              I18n.localize(value, :format => :long)
            else
              value.to_s
            end
          elsif value.is_a?(Time)
            if defined?(I18n)
              I18n.localize(value, :format => :long)
            else
              value.to_s
            end
          else
            value.to_s
          end
        else
          ""
        end
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
      
      private
      
      def set_default_values
        @title||=@name.to_s.humanize
      end
      
      def format_for_datetime value
        if defined?(I18n)
          I18n.localize(value, :format => @format)
        else
          value.to_s
        end
      end

      def validate
        raise ArgumentError.new("Column must have name.") unless self.name
      end
    end
  end
end
