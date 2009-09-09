class Media::FileBase < Media::Base
  self.abstract_class = true

  #Add file to memory, need when save file without real parent id.
  #Example:
  # Media::ImageFile.add_to_memory(1234567,5)
  def self.add_to_memory memory_id,file_id
    Media::MediaFileTempMemory.create!(
      :media_file_id=>file_id,
      :user_id=>Admin::User.current_user.id,
      :memory_id=>memory_id,
      :media=>self.to_s
    )
  end

  #Delete all files with given memeory_id
  def self.delete_all_files(memory_id,in_memory)
    if in_memory
      media_ids=[]
      conditions=["media=? AND memory_id=? AND user_id=?",self.to_s,memory_id,Admin::User.current_user.id]
      Media::MediaFileTempMemory.find(:all, :conditions=>conditions).each{|mem|
        media_ids<<mem.media_file_id
      }
      self.destroy_all(["id IN (?)",media_ids]) unless media_ids.empty?
      Media::MediaFileTempMemory.delete_all(conditions)
    end
  end

  #Delete media file with given id
  def self.delete_file(file_id)
    real_file=self.find_by_id(file_id)
    real_file.destroy if real_file
    self.delete_file_from_memory(file_id)
  end

  #Delete memory object with given id
  def self.delete_file_from_memory(file_id)
    Media::MediaFileTempMemory.delete_all(["media=? AND media_file_id=? AND user_id=?",self.to_s,file_id,Admin::User.current_user.id])
  end

  #Check if has temp files with given id.
  def self.has_memory_container?(memory_id)
    Media::MediaFileTempMemory.count(:memory_id,:conditions=>["memory_id=? AND user_id=? AND media=?",memory_id,Admin::User.current_user.id,self.to_s]).to_i>0
  end

  #Find all media objects with given memory id
  def self.find_in_memory(memory_id,conditions={})
    temp_table=Media::MediaFileTempMemory.table_name
    memory=Media::MediaFileTempMemory.find(:all,:conditions=>self.cms_merge_conditions(["#{temp_table}.memory_id=? AND #{temp_table}.user_id=? AND #{temp_table}.media=?",memory_id,Admin::User.current_user.id,self.to_s],conditions))
    self.find(:all,:conditions=>["#{self.table_name}.id IN (?)",memory.collect{|m| m.media_file_id}])
  end

  #Find all existing media object, that are not kept in memory
  def self.find_existing(class_name,parent_id)
    polymorphic_name=media_get_polymorphic_name
    self.find(:all,:conditions=>["#{polymorphic_name}_type=? AND #{polymorphic_name}_id=?",class_name.camelize,parent_id]) if polymorphic_name
  end

  #Find existing media object or ones that are in memory
  def self.find_current_files class_name,memory_id
    if self.has_memory_container?(memory_id)
      self.find_in_memory(memory_id)
    else
      self.find_existing(class_name,memory_id)
    end
  end
  
  #End of new functions added when changed to media namespace
  def self.new_file(params)
    file=self.new()
     polymorphic_name=media_get_polymorphic_name
    if params[:tempid]!="true" && params[:parent_id]
      parent=params[:parent].camelize.constantize.find_by_id(params[:parent_id])
      file.send("#{polymorphic_name}=",parent) if parent
    else
      file.send("#{polymorphic_name}_type=",params[:parent].camelize)
    end
    file.name=params[params[:media].to_sym][:name] if params[params[:media].to_sym]
    file
  end

  #Remove all media files that are older than one day
  #and witch doesn't have assigned parent ID.
  #Also remove all these media object references from temp media memory.
  def self.clear_temp_files
    polym_name=media_get_polymorphic_name
    memory_ids=[]
    self.find(:all,:conditions=>["#{polym_name}_id IS NULL AND created_at<=?",1.day.ago]).each{|f|
      memory_ids<<f.id
      f.destroy
    }
    Media::MediaFileTempMemory.delete_all(["memory_file_id IN (?)",memory_ids]) unless memory_ids.empty?
  end

  #Function is called from file_manager.rb extensions.
  #Update all files with given memory_id, that are kept in memory, with
  #real object id and right type.
  #Delete object references from temp media memory and refresh real object
  #references with new media objects.
  def self.update_memorized_files(memory_id,parent)
    poly_name=self.media_get_polymorphic_name
    result=self.find_in_memory(memory_id).collect{|obj|
      obj.update_attributes!(:"#{poly_name}_type"=>parent.class.to_s,:"#{poly_name}_id"=>parent.id)
      self.delete_file_from_memory(obj.id)
    }
    self.assing_polymorphic_result_to_object(parent,result,poly_name.to_sym)
    self.clear_temp_files
  end

end