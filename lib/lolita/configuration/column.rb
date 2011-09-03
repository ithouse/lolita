module Lolita
  module Configuration
    class Column 

      include Lolita::Builder
      
      MAX_TEXT_SIZE=20
      lolita_accessor :name,:title,:type,:options,:sortable
      
      def initialize(dbi,*args,&block)
        @dbi=dbi
        self.set_attributes(*args)
        self.instance_eval(&block) if block_given?
        validate
        set_default_values
      end

      def value(record)
        if self.name.to_s.match(/_id$/) && record.respond_to?(self.name.to_s.gsub(/_id$/,"").to_sym)
          remote_record = record.send(self.name.to_s.gsub(/_id$/,"").to_sym)
          if remote_record.respond_to?(:title)
            remote_record.send(:title)
          elsif remote_record.respond_to?(:name)
            remote_record.send(:name)
          else
            record.send(self.name)
          end
        else
          record.send(self.name)
        end
      end

      def title(value=nil)
        @title=value if value
        @title||=@dbi.klass.human_attribute_name(@name.to_s)
        @title
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
      
      # Define format, for details see Lolita::Support::Formatter and Lolita::Support::Formater::Rails
      def formatter(value=nil,&block)
        if block_given?
          @formatter=Lolita::Support::Formatter.new(value,&block) 
        elsif value || !@formatter
          if value.kind_of?(Lolita::Support::Formatter)
            @formatter=value
          else
            @formatter=Lolita::Support::Formatter::Rails.new(value)
          end
        end
        @formatter
      end

      def formatter=(value)
        if value.kind_of?(Lolita::Support::Formatter)
          @formatter=value
        else
          @formatter=Lolita::Support::Formatter::Rails.new(value)
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
            if args[1].is_a?(Hash)
              args[1].each{|m,value|
                self.send("#{m}=".to_sym,value)
              }
            end
          else
            raise ArgumentError.new("Lolita::Configuration::Column arguments must be Hash or Symbol or String instead of #{args[0].class}")
          end
        end
      end
      
      private
      
      def set_default_values
        @sort_direction||=:desc
      end

      def validate
        raise ArgumentError.new("Column must have name.") unless self.name
      end
    end
  end
end
