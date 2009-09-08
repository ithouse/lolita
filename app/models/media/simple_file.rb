class Media::SimpleFile < Media::FileBase
  set_table_name :media_simple_files
  belongs_to :fileable, :polymorphic => true
  upload_column :name,:store_dir=>proc{|inst, attr|
    time=inst.created_at ? inst.created_at : Time.now
    "upload/simple_file/#{time.strftime("%Y_%m")}/#{inst.id}"
  }
  named_scope :by_parent, lambda{|parent,parent_id|
    {:conditions=>["fileable_type=? AND fileable_id=?",parent.to_s.camelize,parent_id]}
  }
 
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
end
