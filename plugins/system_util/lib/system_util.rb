module Util
  class System
    require 'find'

    def self.controller_paths
      #Ielādē projekta modeļus, lolitas modeļus un visus lolitas pluginu modeļus
      ["app/controllers"] + Dir[File.join(RAILS_ROOT,'vendor','plugins','lolita*','app','controllers')].collect{|p| p.gsub("#{RAILS_ROOT}/",'')}.compact
    end

    def self.excluded_namespaces
      ["extensions"]
    end
    
    def self.load_classes(options={})
      @collected_data=[]
      self.controller_paths.each{|path|
        self.collect_classes_from(path)
      }
      @collected_data
    end

    def self.collect_classes_from(path)
      Find.find(File.join(RAILS_ROOT,path)) do |full_path|
        unless File.directory?(full_path)
          self.is_valid_class?(full_path,path) do |file_data|
            @collected_data<<file_data
          end
        end
      end
    end

    def self.is_valid_class?(path,root_path)
      namespaces=File.dirname(path).gsub(File.join(RAILS_ROOT,root_path),"").split("/").collect{|dir|
        dir.to_s.size>0 ? dir : nil
      }.compact
      base_name=File.basename(path,".rb")
      if base_name=~/_controller$/
        file_name=File.join(namespaces+[base_name])
        klass_name=file_name.camelize
        klass=klass_name.constantize
        if klass.is_a?(Class) && klass.ancestors.include?(ApplicationController) && klass!=ApplicationController
          yield :object=>klass,:name=>file_name.gsub(/_controller$/,"")
        end
      end
    end
  end
end