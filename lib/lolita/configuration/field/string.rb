module Lolita
  module Configuration
    module Field
      class String < Lolita::Configuration::Field::Base
        lolita_accessor :simple, :rows
        def initialize dbi,name,*args, &block
          super
          if self.dbi_field && self.dbi_field.options[:native_type] == "text"
            self.builder = :text unless @builder
          end
        end

      end
    end
  end
end
