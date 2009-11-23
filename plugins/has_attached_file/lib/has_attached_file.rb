# SIA ITHouse
# Artūrs Meisters
# 11.08.2008 11:23
module ITHouse
  module HasAttachedFile

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_reader :upload_column_versions,:upload_column_modify_methods

      def has_attached_image_file name, options={}
        configure_attached_picture(name,options)
        self.has_one name, options
      end
      def has_attached_image_files name, options={}
        configure_attached_picture(name,options)
        self.has_many name, options
      end

      private

      def configure_attached_picture name,options={}
        # Define method from association name, for getting url
        # has_many :avatars => object.avatar_url(:main)
        define_method "#{name.to_s.singularize}_url" do |version|
          if self.send(name).is_a?(Array) && !self.send(name).empty?
            collection=self.send(name)
            collection.find(:first,:order=>"main_image desc").name.send(version).url
          elsif !self.send(name).is_a?(Array) && self.send(name)
            self.send(name).name.send(version).url
          end
        end
        @upload_column_versions=options[:versions] ? options[:versions].dup : {}
        @upload_column_modify_methods=options[:modify] ? options[:modify].dup : nil
        options=options.delete_if{|k,v| [:versions,:modify].include?(k)}
      end
    end

  end
end
