module Lolita
  module Configuration
    module Field
      class DateTime < Lolita::Configuration::Field::Base
        attr_accessor :format
        def initialize dbi,name,*args, &block
          
          super
          override_order
        end

        private

        def override_order
          @options[:order] = ::I18n.t("date.order", :default => []).map(&:to_sym)
        end

      end
    end
  end
end
