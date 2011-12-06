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

      def current_sort_state(params)
        @sortable && sort_pairs(params).detect{|pair| pair[0]==self.name.to_s} || []
      end

      def sort_params params
        if @sortable
          pairs = sort_pairs(params)
          found_pair = false
          pairs.each_with_index{|pair,index|
            if pair[0] == self.name.to_s
              pairs[index][1] = pair[1] == "asc" ? "desc" : "asc"
              found_pair = true
            end
          }
          unless found_pair
            pairs << [self.name.to_s,"asc"]
          end
          (pairs.map{|pair| pair.join(",")}).join("|")
        else
          ""
        end
      end

      def sort_pairs params
        (params[:s] || "").split("|").map{|pair| pair.split(",")}
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
        options = args ? args.extract_options! : {}
        if args[0].respond_to?(:field)
          [:name,:type].each do |attr|
            self.send(:"#{attr}=",args[0].send(attr))
          end
        elsif args[0]
          self.name = args[0]
        end
        options.each do |attr_name,value|
          self.send(:"#{attr_name}=",value)
        end
      end
      
      private

      def validate
        raise ArgumentError.new("Column must have name.") unless self.name
      end
    end
  end
end
