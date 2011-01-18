module Lolita
  class Cells < Cell::Rails
    helper Lolita::Controllers::InternalHelpers
    class << self
      def require_project_cell(name)
        if defined?(Rails.root)
          require File.join(RAILS_ROOT,"app","cells","lolita",name)
        end
      end

      def require_lolita_cell(name)
        require File.join(LOLITA_APP_ROOT,"cells","lolita",name)
      end
    end

    def render(options={})  #TODO pielikt konfigurācijā lai var salādēt cell pathus, un šeit tad viņus sakārtot
      puts self.view_paths.inspect
      new_path=File.join(RAILS_ROOT,"app","cells")
      if File.exist?(new_path) && !self.view_paths.include?(new_path)
        self.view_paths.unshift(new_path)
      end
      lolita_paths=[LOLITA_APP_ROOT,"cells"]
      new_lolita_path=File.join(*lolita_paths)
      unless self.view_paths.include?(new_lolita_path)
        self.view_paths.push(new_lolita_path)
      end
      super options
    end
    
    #    def view_paths
    #      if defined?(RAILS_ROOT)
    #        paths=super
    #        new_path=File.join(RAILS_ROOT,"app","cells")
    #        paths+[new_path]
    #      else
    #        super
    #      end
    #    end
  end
end