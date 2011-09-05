module Lolita
  module Adapter
    module FieldHelper
      def technical?
        if self.name.to_s.match(/^created_at|updated_at|type$/)
          true
        elsif self.primary?
          true
        elsif adapter.klass.respond_to?(:uploaders)
          adapter.klass.uploaders.keys.include?(name.to_sym)
        end
      end

      def content?
        !technical?
      end
    end
  end
end