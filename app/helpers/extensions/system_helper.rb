module Extensions::SystemHelper
        
  def related_parents
    params.each{|key,value|
      if key.include?("_id")
        yield key,value
      end
    }
  end
  
  def get_tables_for_menu menu_id, options={}
    tables=[]
    Admin::Menu.accessable_modules(menu_id,options) do |name,controller|
      tables<<[name.camelize, options[:simple] ? controller : "/#{controller}"]
    end
    tables=options[:include]+tables if options[:include]
    tables=[[t(:"fields.select a module"),'']]+tables
    tables
  end
  
end
