module Lolita
  module Configuration
    class TextareaField < Lolita::Configuration::Field

      lolita_accessor :rows
      def initialize *args, &block
        @type="textarea"
        super
      end
      def rows row_count
        @row_count = row_count
      end
    end
  end
end