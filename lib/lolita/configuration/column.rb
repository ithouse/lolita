module Lolita
  module Configuration
    class Column 

      include Lolita::Builder
      
      MAX_TEXT_SIZE=20
      lolita_accessor :name,:title,:type,:options,:sortable
      
      def initialize(*args,&block)
        self.set_attributes(*args)
        self.instance_eval(&block) if block_given?
        validate
        set_default_values
      end

      def sortable?
        @sortable
      end

      def currently_sorting?(params)
        @sortable && params[:sc].to_s==self.name.to_s
      end

      def sort_options(params)
        direction=if params[:sc].to_s==self.name.to_s
          params[:sd].to_s=="asc" ? "desc" : "asc"
        else
          "desc"
        end
        {:sc=>self.name,:sd=>direction}
      end
      
      # Define format, for details see Lolita::Support::Formatter::Base and Lolita::Support::Formater::Rails
      def formatter(value=nil,&block)
        if block_given?
          @formatter=Lolita::Support::Formatter::Base.new(value,&block) 
        elsif value || !@formatter
          @formatter=Lolita::Support::Formatter::Rails.new(value)
        end
        @formatter
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
        @sortable||=true
        @sort_direction||=:desc
        @title||=@name.to_s.humanize
      end

      def validate
        raise ArgumentError.new("Column must have name.") unless self.name
      end
    end
  end
end
