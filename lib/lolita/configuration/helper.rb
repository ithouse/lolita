module Lolita
  module Configuration
    module Helper
      class << self
        # Return true if field name matches one of these:
        # * created_at, updated_at, type
        # * ends with _id, but there is no association that uses that field as foreign_key
        # * there are uploader with that name
        def tehnical_field?(db_field,dbi)
          name = db_field[:name].to_s
          if name.match(/^created_at|updated_at|type$/)
            true
          elsif name.match(/_id$/)
            # FIXME move this to dbi association proxy
            key_method = dbi.adapter_name == :active_record ? :association_foreign_key : :key
            assoc = dbi.associations.values.detect{|assoc| assoc.send(key_method) == name}
            !assoc || assoc.options[:polymorphic]
          elsif dbi.klass.respond_to?(:uploaders)
            dbi.klass.uploaders.keys.include?(name.to_sym)
          end
        end
      end
    end
  end
end