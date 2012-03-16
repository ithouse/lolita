module Lolita
  # Every class that include Lolita::Configuration this module assign
  # #lolita and #lolita= methods. First one is for normal Lolita configuration
  # definition, and the other one made to assing Lolita to class as a Lolita::Configuration::Base
  # object. You may want to do that to change configuration or for testing purpose.
  # Lolita could be defined inside of any class that is supported by Lolita::Adapter, for now that is
  # * ActiveRecord::Base
  # * Mongoid::Document
  module Configuration

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

    class Base
      include Lolita::Builder
      attr_reader :dbi

      private

      # Used to set attributes if block not given.
      def set_attributes(*args)
        options = args && args.extract_options! || {}
        options.each do |attr_name,value|
          self.send("#{attr_name}=".to_sym,value)
        end
      end

    end

  end
end

