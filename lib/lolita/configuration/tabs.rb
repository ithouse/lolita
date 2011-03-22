module Lolita
  module Configuration
    # Lolita::Configuration::Tabs is container class that holds all
    # tabs for each lolita instance. 
    # Also it has some useful methods.

    class Tabs
      include Enumerable
      include Lolita::ObservedArray
      include Lolita::Builder

      attr_reader :dbi,:excluded
      def initialize dbi,*args,&block
        @dbi=dbi
        @tabs=[]
        @excluded=[]
        self.set_attributes(*args)
        self.instance_eval(&block) if block_given?
      end

      def each
        if @tabs.empty?
          create_content_tab
        end
        
        @tabs.each{|tab|
          yield tab
        }
      end

      def tabs=(values)
        if values.is_a?(Array)
          values.each{|tab|
            self<<tab
          }
        else
          raise ArgumentError, "Tabs must be specified as Array."
        end
      end

      def tab *args,&block
        self<<Lolita::Configuration::Tab.add(@dbi,*args,&block)
      end

      def by_type(type)
        @tabs.detect{|tab| tab.type==type.to_sym}
      end

      def exclude=(values)
        exclude(values)
      end

      def default=(values)
        default(values)
      end
      
      def default *args
        tab_types=if args
          args
        else
          default_tab_types
        end
        tab_types.each{|type|
          self<<Lolita::Configuration::Tab.new(@dbi,type.to_sym)
        }
      end

      def exclude *args
        @excluded=if args && args.include?(:all)
          default_tab_types
        else
          args
        end
      end

      def names
        @tabs.map(&:name)
      end
      
      def set_attributes *args
        if args
          attributes=args.extract_options!
          attributes.each{|attribute,values|
            self.send(:"#{attribute}=",values)
          }
        end
      end

      private

      def create_content_tab
        tab(:content)
      end
      
      def validate_type(tab)
        if tab && tab.type!=:default
          if @tabs.detect{|c_tab| c_tab.type==tab.type}
            raise Lolita::SameTabTypeError, "Same type tabs was detected (#{tab.type})."
          end
        end
      end
      
      def default_tab_types
        Lolita::Configuration::Tab.default_types
      end

      def set_tab_attributes(tab)
        if tab
          tab.name="tab_#{@tabs.size}" unless tab.name
        end
      end

      def collection_variable
        @tabs
      end

      def build_element(element,&block)
        current_tab=if element.is_a?(Hash) || element.is_a?(Symbol)
          Lolita::Configuration::Tab.new(@dbi,element,&block)
        else
          element
        end
        set_tab_attributes(current_tab)
        validate_type(current_tab)
        current_tab
      end
    end
  end
end