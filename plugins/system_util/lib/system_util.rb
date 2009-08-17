module Util
  class System
    require 'find'
    def self.list_directory(dir_name,options={})
      paths=[]
      full_dir_name = File.join(RAILS_ROOT,dir_name)
      list_simple_directory(full_dir_name,options){|value| paths<<value}
      if options[:include_root]
        path_parts=dir_name.split("/")
        path_parts.pop
        root_path=File.join(RAILS_ROOT,path_parts)
        list_simple_directory(root_path,:only_module_name=>true){|value| paths<<value}
      end
      paths
    end

    def self.model_paths
      [ "app/models",
        "vendor/plugins/lolita/app/models"
      ]
    end

    def self.get_data_models(options={})
      get_models(options.merge({:namespaces=>:all,:exclude_namespaces=>"extensions"}))
    end
    
    def self.get_extension_models(options={})
      get_models(options.merge({:namespaces=>"extensions"}))
    end

    def self.get_models(options={:include_root=>true})
      class_list=[]
      #validējam :namespaces iespējamās vērtības
      namespaces = if options[:namespaces].is_a?(Array) || options[:namespaces] == :all
        options[:namespaces]
      elsif options[:namespaces].is_a?(String)
        [options[:namespaces]]
      else
        nil
      end
      #validējam sarakstā neiekļaujamos namespacus
      exclude_namespaces = if options[:exclude_namespaces].is_a?(Array)
        options[:exclude_namespaces]
      elsif options[:exclude_namespaces].is_a?(String)
        [options[:exclude_namespaces]]
      else
        []
      end
      if !namespaces
        #ja netiek prasīti namespaci tad ielasa arī visus modeļus kas ir rootā
        model_paths.each{|path|
          class_list+=list_directory(path,options)
        }
      end
      model_paths.each{|root|
        Dir.foreach(root) do |subdir|
          if ! (subdir == "." || subdir == "..")
            path=File.join(RAILS_ROOT,root,subdir)
            allowed_namespace=!namespaces || (namespaces && ((namespaces==:all && !exclude_namespaces.include?(subdir))||(namespaces!=:all && namespaces.include?(subdir))))
            if !path.match(/\.svn|\.git/) && File.directory?(path) && allowed_namespace && !subdir.match(/\./)
              class_list+=list_directory(File.join(root,subdir),options)
              options.delete(:include_root) #dumjš risinājums, lai neiekļautu rootu otriez
            end
          end
        end
      }
      return class_list.sort!{|x,y| x[:object] <=> y[:object] }
    end
    
    protected
    def self.list_simple_directory(path,options={})
      Find.find(path) do |fullpath|
        if !fullpath.match(/\.svn|\.git/)
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