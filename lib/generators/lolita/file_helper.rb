module Lolita
  module Generators
    module FileHelper

      private

      def copy_dir(source,options={})
        root_dir=File.join(options[:root] || LOLITA_ROOT,source)
        Dir[File.join(root_dir, "**/*")].each do |file|
          relative = file.gsub(/^#{root_dir}\//, '')
          if File.file?(file)
            copy_file file, File.join(Rails.root, source, relative)
          end
        end
      end

      def file_exists? path
        File.exists?(File.join(destination_root, path))
      end
    end
  end
end
