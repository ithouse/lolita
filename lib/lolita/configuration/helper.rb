module Lolita
  module Configuration
    module Helper
      class << self
        # Return true if field name matches one of these:
        # * created_at, updated_at, type
        # * ends with _id, but there is no association that uses that field as foreign_key
        # * there are uploader with that name
        def tehnical_field?(db_field,dbi)
          if db_field.name.to_s.match(/^created_at|updated_at|type$/)
            true
          elsif db_field.primary?
            true
          elsif dbi.klass.respond_to?(:uploaders)
            dbi.klass.uploaders.keys.include?(name.to_sym)
          end
        end
      end
    end
  end
end