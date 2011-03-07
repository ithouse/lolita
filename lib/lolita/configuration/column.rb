module Lolita
  module Configuration
    class Column 

      MAX_TEXT_SIZE=20
      DEFAULT_DATE_FORMAT="%Y-%m-%d"
      DEFAULT_TIME_FORMAT="%H:%M:%S"
      attr_writer :name, :title, :type, :options,:format
      
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

      def format(value=nil)
        self.format=value if value
        @format
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
        if @format
          @format.call(value)
        else
          format_from_type(value)
        end
      end

      def format_from_type(value) #TODO test
        if value
          case self.type.to_s.downcase
          when "string"
            value
          when "integer"
            value
          when "text"
            new_value=value.to_s.gsub(/<\/?[^>]*>/, "").strip
            if new_value.size>MAX_TEXT_SIZE
              "#{new_value.slice(0..MAX_TEXT_SIZE)}..."
            else
              new_value
            end
          when "datetime"
            value.strftime("#{DEFAULT_DATE_FORMAT} #{DEFAULT_TIME_FORMAT}")
          when "date"
            value.strftime(DEFAULT_DATE_FORMAT)
          when "time"
            value.strftime(DEFAULT_TIME_FORMAT)
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
      
    end
  end
end
