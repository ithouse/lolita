class Admin::Table < Cms::Base
  set_table_name :admin_tables

  validates_presence_of :name
  validates_uniqueness_of :name

  named_scope :in_namespace, lambda{|namespace, all|
    {:conditions=>["admin_tables.name LIKE ? #{all ? "OR admin_tables.name NOT LIKE ?" : ""}","#{namespace}/%"]+(all ? ["%/%"]: [])}
  }
  named_scope :exclude_names,lambda{|names|
    {:conditions=>["admin_tables.name NOT IN (?)",names]}
  }
  named_scope :by_human_name,lambda{|direction|
    {:order=>"admin_tables.human_name #{direction || "asc"}"}
  }
  def self.collect_modules
    existing=existing_table_names
    unneeded=existing-collect_real_tables(Util::System.get_all_modules(:include_root=>true),existing)
    remove_tables(unneeded)
  end

  def self.existing_table_names
    self.find(:all).collect{|rec|
      rec.name
    }
  end

  def self.collect_real_tables(fs_modules,existing_tables)
    real_tables=[]
    fs_modules.each{|table|
      real_tables<<table[:name] if is_valid_object?(table[:name].camelize.constantize,:all=>true)
      unless existing_tables.include?(table[:name])
        existing_tables<<table[:name]
        self.create(:name=>table[:name])
      end
    }
    real_tables
  end
  
  def self.remove_tables tables
    (tables).each{|name|
      Admin::Field.remove_by_table(name)
      self.find_by_name(name).destroy
    }
  end


  def self.is_valid_object?(object,options={})
    ancestors=object.ancestors
    valid_ancestors=ancestors.include?(Cms::Manager) || ancestors.include?(Cms::Content)
    is_abstract=object.respond_to?("abstract_class?") && object.abstract_class?
    (!is_abstract || (is_abstract && valid_ancestors)) && ((valid_ancestors) || (options[:all] && ancestors.include?(Cms::Base)))
  end

  def humanized_name
    self.human_name.to_s.size>0 ? self.human_name : self.name.split("/").last.humanize
  end
end
