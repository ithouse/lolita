module Lolita
   # All classes that want to use lolita for configuration should include this module.
  module Configuration
    # When Lolita::Configuration is included, it add hook for class <em>:after_lolita_loaded</em> and define class methods
    # <em>lolita</em> and <em>lolita=</em> and instance method <em>lolita</em> that refers to class method with same name.
    def self.included(base)
      base.class_eval do
        include Lolita::Hooks
        add_hook :after_lolita_loaded

        extend ClassMethods
        def lolita
          self.class.lolita
        end
      end
    end

    module ClassMethods
      # This is main method for configuration, it initialize new Lolita::Configuration::Core object, that have other methost to 
      # define different parts of configuration.
      def lolita(&block)
        Lolita::LazyLoader.lazy_load(self,:@lolita,Lolita::Configuration::Core,self,&block)
      end
      
      def lolita=(value)
        if value.is_a?(Lolita::Configuration::Core) || value.nil?
          @lolita = value
        else
          raise ArgumentError.new("Only Lolita::Configuration::Core is acceptable.")
        end
      end
    end
  end
end