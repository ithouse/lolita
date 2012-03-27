module Lolita
  module Configuration
    # Lolita::Configuration::Tabs is container class that holds all
    # tabs for each lolita instance. 
    # Also it has some useful methods.
    class Tabs < Lolita::Configuration::Base
      include Enumerable
      include Lolita::ObservedArray

      attr_reader :excluded
      attr_accessor :tab_types

      def initialize dbi,*args,&block
        set_and_validate_dbi(dbi)
        set_default_attributes
        set_attributes(*args)
        self.instance_eval(&block) if block_given?
      end

      def each
        create_content_tab if @tabs.empty?
        @tabs.each{|tab| yield tab }
      end

      def tabs=(values)
        if values.respond_to?(:each)
          values.each{|tab| self << tab}
        else
          raise ArgumentError, "#{values} must respond to each"
        end
      end

      def tab *args,&block
        self << build_element(args && args[0],&block)
      end

      def fields
        @tabs.map(&:fields).flatten
      end

      def by_type(type)
        @tabs.detect{|tab| tab.type == type.to_sym }
      end

      def names
        @tabs.map(&:name)
      end

      def associated
        @tabs.select{|tab| !tab.dissociate}
      end

      def dissociated
        @tabs.select{|tab| tab.dissociate}
      end
      
      def default
        tab_types.each{|type| tab(type.to_sym)}
      end

      private

      def set_default_attributes()
        @tabs=[]
        @tab_types = [:content]
      end

      def create_content_tab
        tab(:content)
      end
      
      def validate(tab)
        tab.respond_to?(:validate) && tab.send(:validate, :tabs => @tabs)
      end

      def collection_variable
        @tabs
      end

      def build_element(possible_tab,&block)
        possible_tab = possible_tab.nil? && :default || possible_tab
        new_tab = if possible_tab.is_a?(Hash) || possible_tab.is_a?(Symbol)
          Lolita::Configuration::Factory::Tab.add(dbi,possible_tab,&block)
        else
          possible_tab
        end
        validate(new_tab)
        new_tab
      end
    end
  end
end