# SIA ITHouse
# Artūrs Meisters
# 11.08.2008 11:23
module ITHouse
  module HasAttachedFile

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_reader :upload_column_versions

      def has_attached_image_file name, options={}
        configure_attached_picture(options)
        self.has_one name, options
      end
      def has_attached_image_files name, options={}
        configure_attached_picture(options)
        self.has_many name, options
      end

      private

      def configure_attached_picture options={}
        @upload_column_versions=options[:versions] ? options[:versions].dup : {}
        options=options.delete_if{|k,v| k==:versions}
      end
    end

  end
end