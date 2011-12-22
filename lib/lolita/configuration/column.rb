module Lolita
  module Configuration
    class Column 

      include Lolita::Builder
      
      MAX_TEXT_SIZE=20
      attr_reader :dbi
      lolita_accessor :name,:title,:type,:options,:sortable, :association
      
      def initialize(dbi,*args,&block)
        @dbi = dbi
        self.set_attributes(*args)
        self.instance_eval(&block) if block_given?
        validate
        normalize_attributes
        detect_association
      end

      def list *args, &block
        if args && args.any? || block_given?
          detect_association
          list_association = args[0] && @dbi.associations[args[0].to_s.to_sym] || self.association
          list_dbi = list_association && Lolita::DBI::Base.create(list_association.klass)
          raise Lolita::UnknownDBIError.new("DBI is not specified for list in column #{self}") unless list_dbi
          Lolita::LazyLoader.lazy_load(self,:@list,Lolita::Configuration::List, list_dbi, :parent => self, &block)
        else
          Lolita::LazyLoader.lazy_load(self,:@list,Lolita::Configuration::List)
        end
      end

      # Return value of column from given record. When record matches foreign key patter, then foreign key is used.
      # In other cases it just ask for attribute with same name as column.
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

      def formatted_value(record,view)
        self.formatter.with(self.value(record),record,self)
      end

      # Set/Get title. Getter return title what was set or ask for human_attribute_name to model.
      def title(value=nil)
        @title=value if value
        @title||=@dbi.klass.human_attribute_name(@name.to_s)
        @title
      end

      def sortable?
        @sortable
      end

      # Find if any of received sort options matches this column.
      def current_sort_state(params)
        @sortable && sort_pairs(params).detect{|pair| pair[0]==self.name.to_s} || []
      end

      # Return string with sort options for column if column is sortable.
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

      # Create array of sort information from params.
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

      def detect_association
        @association ||= dbi.associations[self.name]
      end

      def normalize_attributes
        @name = @name.to_sym
      end

      def validate
        raise ArgumentError.new("Column must have name.") unless self.name
      end
    end
  end
end
