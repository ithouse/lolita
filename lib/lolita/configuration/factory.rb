module Lolita
  module Configuration
    module Factory
      
      def temp_object?
        @create_temp_object||=false
        @create_temp_object
      end

      def add(dbi,*args,&block)
        @create_temp_object=true
        begin
          temp_object=self.const_get(:Base).new(dbi,*args,&block)
        rescue Exception => e
          raise e
        ensure
          @create_temp_object=false
        end
        factory(temp_object.type).new(dbi,*args,&block)
      end


      protected

      def factory(name)
        begin
          self.const_get(:"#{to_class(name)}")
        rescue NameError
          error_class=Lolita::ConfigurationClassNotFound
          raise error_class, "Can't find #{self}::#{to_class(name)}. Should be in /configuration/#{factory_name}/#{name}.rb"
        end
      end

      def to_class(name)
        name.to_s.downcase.gsub(/_id$/, "").gsub(/(^\w|_\w)/) do |m|
          m.gsub("_","").upcase
        end
      end

      def factory_name
        @factory_name||=self.to_s.split("::").last.downcase
        @factory_name
      end
    end
  end
end