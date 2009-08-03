class FileItem < FileBase
  set_table_name :files
  belongs_to :fileable, :polymorphic => true
  upload_column :name,:store_dir=>proc{|inst, attr|
    time=inst.created_at ? inst.created_at : Time.now
    "upload/file_item/#{time.strftime("%Y_%m")}/#{inst.id}"
  }
  named_scope :by_parent, lambda{|parent,parent_id|
    {:conditions=>["fileable_type=? AND fileable_id=?",parent.to_s.camelize,parent_id]}
  }
  def self.new_from_params(params)
    file = self.new_file(params)
    file.add_permissions(params[:file][:permission],params) if params[params[:media].to_sym]
    file
  end

  def self.file_ext type
    FileItem::MIME_EXTENSIONS[type]
  end
  def self.create_file dir,name,data
    f = File.new(RAILS_ROOT+"/"+dir+"/"+name,  "w+b")
    #f.chmod("660")
    f.puts(data) 
    f.close
    f
  end

  def add_permissions pemissions, params
    self.is_public=params[:private]=="true" ? nil : true
    if pemissions
      if pemissions[:user]
        self.user_id=pemissions[:user] if pemissions[:user].to_i>0
      end
      if pemissions[:role]
        self.role_id= pemissions[:role] if pemissions[:role].to_i>0
      end
    end
  end
end
