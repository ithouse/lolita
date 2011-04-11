module Lolita
  module Configuration
    class Filter
      include Lolita::Builder
      attr_reader :dbi

      def initialize(dbi,*args,&block)
        @dbi = dbi
        @fields=Lolita::Configuration::Fields.new
        set_attributes(*args)
        self.instance_eval(&block) if block_given?
      end

      def field *args, &block
        field=Lolita::Configuration::Field.add(self.dbi,*args,&block)
        field
        @fields<<field
        field
      end

      # Set all fields in tab. Accept <code>fields</code> as Array.
      # Each array element can be Lolita::Configuration::Field object or
      # Hash, that will be passed to #field method.
      def fields=(fields)
        if fields.is_a?(Array)
          fields.each{|field_attr|
            if field_attr.is_a?(Lolita::Configuration::Field)
              @fields<<field_attr
            else
              self.field(field_attr)
            end
          }
        end
      end

      def fields(*args, &block)
        unless args.empty?
          args.each do |field_name|
            f = field(field_name)
            f.instance_eval(&block) if block_given?
          end
        end
        if @fields.empty?
          field :search
        end
        @fields
      end

      # Used to set attributes if block not given.
      def set_attributes(*args)
        if args && args[0]
          if args[0].is_a?(Hash)
            args[0].each{|m,value|
              self.send("#{m}=".to_sym,value)
            }
          else
            fields *args            
          end
        end
      end

      def field_name field
        ('a'..'z').to_a[self.fields.index(field)]
      end
    end
  end
end