module Util
  class System
    require 'find'
    def self.list_directory(dir_name,options={})
      paths=[]
      full_dir_name = RAILS_ROOT+'/'+dir_name
      list_simple_directory(full_dir_name,options){|value| paths<<value}
      if options[:include_root]
        path_parts=dir_name.split("/")
        path_parts.pop
        root_path=RAILS_ROOT+"/"+path_parts.join("/")
        list_simple_directory(root_path,:only_module_name=>true){|value| paths<<value}
      end
      paths
    end
    
    def self.get_all_modules(options={})
      class_list=[]
      root=RAILS_ROOT+"/app/models"
      unless options[:namespaces]
        class_list+=list_directory("app/models",options)
      end
      Dir.foreach(root) do |subdir|
        path="#{root}/#{subdir}"
        allowed_namespace=!options[:namespaces] || (options[:namespaces] && options[:namespaces].include?(subdir))
        if !path.match(/\.svn/) && File.directory?(path) && allowed_namespace && subdir!=("extensions") && !subdir.match(/\./)
          class_list+=list_directory("app/models/#{subdir}",options)
          options.delete(:include_root) #dumjš risinājums, lai neiekļautu rootu otriez
        end
      end
      return class_list
    end
    
    protected
    def self.list_simple_directory(path,options={})
      Find.find(path) do |fullpath|
        if !fullpath.match(/\.svn/)
          dirname=File.dirname(fullpath)
          namespace="#{dirname.split("/").last}/"
          namespace=namespace=="models/" ? nil : namespace
          if !File.directory?(fullpath) && File.extname(fullpath)==".rb"  && !dirname.match(/\.\z/) && dirname==path
            file_name=!options[:only_module_name] ? "#{namespace}#{File.basename(fullpath,".rb")}" : File.basename(fullpath,".rb")
            if file_name && file_name!='home'
              element={:object=>file_name.camelize,:name=>file_name}
              yield element
            end
          end
        end
      end
    end
    
  end
end