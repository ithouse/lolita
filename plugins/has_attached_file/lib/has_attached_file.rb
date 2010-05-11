# coding: utf-8
# SIA Lolita
# Artūrs Meisters
# 11.08.2008 11:23
module Lolita
  module HasAttachedFile

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_reader :upload_column_versions,:upload_column_modify_methods

      # Binds an image file specified by <tt>name</tt> to the model.
      #
      # You can generate different versions of the original image by
      # specifying <tt>:versions</tt> hash with :version_name=>"size options".
      # Size options specified as "{width}x{height}" (e.g. "100x100") set the maximum
      # dimensions to resize, prepending with "c" (e.g. "c100x100") crops out the
      # middle portion of the specified size.
      #
      # By default versions :cropped and :thumb are provided.
      #
      # Additionally, you can specify a <tt>:modify</tt> hash of the form
      #  :modification or filter name=>{[:versions=>[array of version names] ]}
      # where :modification/filter name is one of the methods in Media::Extensions::ImageFileExtensions.
      # Several modification can be applied to the same version or original.
      #
      # <b>Gotcha Note</b> for :modify to work the model must directly stem from Cms::Base,
      # otherwise include Media::Extensions::ImageFileExtensions directly in your model.
      #
      # Example: Company model
      #
      #  has_attached_image_file(:logo,
      #    :as=>:pictureable,
      #    :dependent=>:destroy,
      #    :extend=>Extensions::ImageFileExtensions,
      #    :class_name=>"Media::ImageFile",
      #    :versions=>{
      #      :small=>"150x200",
      #      :cropout=>"c150x200",
      #      :small_grayscale=>"150x200",
      #    },
      #    :modify => {
      #      :image_file_grayscale=>{:versions=>[:small_grayscale]},
      #      :image_file_auto_contrast=>{:versions=>[:small_grayscale]},
      #    }
      #   )
      #
      # Here two filters are applied to the :small_grayscale version:
      # * first the image is converted from color, to grayscale
      # * then the grayscale image is enhanced by applying an auto-contrast filter
      #
      # To enable the users to upload the image files, specify a tab in the corresponding
      # controller like this:
      #  {:type=>:multimedia,:media=>:image_file, :single=>true|false,:main_image=>true|false}
      # Use :single=>false for multiple image uploads (using has*image_files).
      # Set :main_image=>true to enable the user to specify a "cover" image from many uploads
      # (e.g. a main image for a car, and then it's displays from different angles).
      #
      # To set the src attribute for the <img> tag, use one of the corresponding (as for the
      # example above):
      #  company.logo_url
      #  company.logo.url
      #  company.logo.name.url
      #  company.logo.name.url(:version)
      #  company.logo.name.version.url
      #  company.logo.main_image.url
      #  company.logo.url(:small_grayscale)
      #
      def has_attached_image_file name, options={}
        configure_attached_picture(name,options)
        self.has_one name, options
      end

      # Create has_many relation, for arguments detail see #has_attached_image_file
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
