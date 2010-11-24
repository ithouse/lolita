module Lolita
  module DBI
    # Lolita::DBI::Base is DataBase Interface class, that handle the request to ORM classes.
    # Depending on given class DBI::Base detect which ORM class is used and include right adapter
    # for that class. Other Lolita classes that need to manipulate with data need to have dbi object
    # or it can be created in that class.
    # Lolita::DBI::Base support Mongoid and ActiveRecord::Base, or details see Lolita::Adapter.
    class Base

      attr_reader :adapter_name #return connected adapter name
      attr_reader :klass # return related orm class object
      attr_reader :adapter # connected Adaptee for adapter
      # Expect ORM class that is supported by Lolita. See Adapter for available adapters.
      def initialize(class_object) 
        @klass=class_object
        detect_adapter
        connect_adapter
      end

      # Detect which ORM class is given and based on it connect Adapter.
      def detect_adapter
        if defined?(Mongoid) && defined?(Mongoid::Document) && self.klass.ancestors.include?(Mongoid::Document)
          @adapter_name=:mongoid
        elsif defined?(ActiveRecord) && defined?(ActiveRecord::Base) && self.klass.ancestors.include?(ActiveRecord::Base)
          @adapter_name=:active_record
        else
          raise NotORMClassError.new("Lolita::DBI::Base can not find appropriate #{self.klass} class adapter.")
        end
      end

      # Connect Adapter by including adapter module into DBI::Base class.
      def connect_adapter()
        @adapter="Lolita::Adapter::#{self.adapter_name.to_s.camelize}".constantize.new(self)
      end

      def method_missing(metod,*args,&block)
        @adapter.send(metod,*args,&block)
      end

      class << self
        # Return Array of available adapters.
        def adapters
          Dir[File.expand_path(File.join(File.dirname(__FILE__),'..','adapter','**','*.rb'))].map {|f|
            File.basename(f,".rb").to_sym
          }.reject{|el| el==:abstract_adapter}
        end
      end
    end
  end
end
