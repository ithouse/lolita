# Abstract class that include methods for working with #Media classes that handle files.
#
# When new *Media* class is created and you can't decide which class need to extend
# Media::Base or Media::FileBase, then here is few tips for you:
# * your class uploads files - extend Media::FileBase
# * your class need to user temporary storage for data before object is created - extend Media::FileBase
# * your class operate with different kind of media, that don't need tempororay storage - extend Media::Base
# * your class need temporary storage - extend Media::FileBase.
class Media::FileBase < Media::Base
  self.abstract_class = true

  # Return temp id that is used as memory id when uploading files.
  # IMPORTANT
  # For all file uploads for one object, use same memory id, so when updating
  # files you can update all at same time, otherwise you must call #update_memorized_files
  # with different memory id.
  # ID is generated in appropriate +size+ (default 15) and accept options.
  # Now only available options is +:strong+ that guarantee that ID is unique.
  def self.get_memory_id(size=15,options={})
    number=lambda{Array.new(size){|i| rand(10)}.join("").to_i}
    if options[:strong]
      num=number.call
      while Media::MediaFileTempMemory.find_by_memory_id(num)
        num=number.call
      end
      num
    else
      number.call
    end
  end
  # Is used to store file in memory. That is useful when
  # object that media object belongs not still created.
  # For storing +memory_id+ is used as uniqe identificator see #get_memory_id and also
  # +file_id+ that is real media object id.
  # ====Example
  #     Media::ImageFile.add_to_memory(1234567,5) #=> Create new #Media::MediaFileTempMemory class.
  def self.add_to_memory memory_id,file_id
    Media::MediaFileTempMemory.create!(
      :media_file_id=>file_id,
      :user_id=>Admin::User.current_user.id,
      :memory_id=>memory_id,
      :media=>self.to_s
    )
  end

  # Delete all files with given +memory_id+, is used to singularize object files.
  # +in_memory+ determined that file no realy still linked with object, but +current+ that
  # new files is already created and passed to this method.
  # For details of usage see Media::ControllerFileBase#new_create.
  def self.delete_all_files(memory_id,in_memory,current=nil)
    if in_memory
      media_ids=[]
      conditions=["media=? AND memory_id=? AND user_id=?",self.to_s,memory_id,Admin::User.current_user.id]
      Media::MediaFileTempMemory.find(:all, :conditions=>conditions).each{|mem|
        media_ids<<mem.media_file_id
      }
      self_conditions=["id IN (?)",media_ids]
      if current
        self_conditions[0]<<" AND id!=?"
        self_conditions<<current.id
      end
      self.destroy_all(self_conditions) unless media_ids.empty?
      Media::MediaFileTempMemory.delete_all(conditions)
    else
      if current
        polymorphic_name=media_get_polymorphic_name
        self.destroy_all(["id!=? AND #{polymorphic_name}_type=? AND #{polymorphic_name}_id=?",
            current.id,current.send(:"#{polymorphic_name}_type"),current.send(:"#{polymorphic_name}_id")
          ])
      end
    end
  end

  #Delete media file with given id or object
  # Delete media file and delete all references from memory too (see #delete_file_from_memory).
  # Allow +file+ to be ID of media file record or record itself.
  # ====Example
  #     Media::ImageFile.delete_file(1) #=> Delete file if found with id 1.
  #     Media::ImageFile.delete_file(Media::ImageFile.find(:first)) #=> delete first image file
  def self.delete_file(file)
    file_id=if(file.is_a?(Media::FileBase))
      file.destroy
      file.id
    else
      real_file=self.find_by_id(file)
      real_file.destroy if real_file
      file
    end
    self.delete_file_from_memory(file_id)
  end

  # Delete file with given +file_id+ from memory for current media class and current user.
  # Used to clean up memory table and remove unnecessary references.
  def self.delete_file_from_memory(file_id)
    Media::MediaFileTempMemory.delete_all(["media=? AND media_file_id=? AND user_id=?",self.to_s,file_id,Admin::User.current_user.id])
  end

  # Determine whether there is an object in memory with given +memory_id+.
  # That is useful when check if temp ID is still in use.
  def self.has_memory_container?(memory_id)
    Media::MediaFileTempMemory.count(:memory_id,:conditions=>["memory_id=? AND user_id=? AND media=?",memory_id,Admin::User.current_user.id,self.to_s]).to_i>0
  end

  # Find all media object for given not-existing parent with +memory_id+ and with additional
  # +conditions+ for #Media::MediaFileTempMemory records filtering.
  # Return real media objects unless parent object not been create yet.
  def self.find_in_memory(memory_id,conditions=[])
    temp_table=Media::MediaFileTempMemory.table_name
    memory=Media::MediaFileTempMemory.find(:all,:conditions=>self.merge_conditions(["#{temp_table}.memory_id=? AND #{temp_table}.user_id=? AND #{temp_table}.media=?",memory_id,Admin::User.current_user.id,self.to_s],conditions))
    self.find(:all,:conditions=>["#{self.table_name}.id IN (?)",memory.collect{|m| m.media_file_id}])
  end

  # Find media records for existing parent object with +parent_id+ and
  # given +class_name+ because all of media tables are polymorphic.
  # Additional +conditions+ also can be passed to filter current media records.
  # ====Example
  #     Media::ImageFile.find_existing("User",1, ["created_at>?",1.year.ago])
  #     #=> Return all image files for user with ID 1, that is newer than 1 year.
  def self.find_existing(class_name,parent_id,conditions=[])
    polymorphic_name=media_get_polymorphic_name
    if polymorphic_name
      conditions=self.merge_conditions(
        ["#{polymorphic_name}_type=? AND #{polymorphic_name}_id=?",class_name.camelize,parent_id],
        conditions
      )
      self.find(:all,:conditions=>conditions)
    end
  end

  # Find files for object that can be already created or not.
  # For that reason +class_name+ need to be passed and +memory_id+ too, that may
  # be real object ID or true memory id, it is possible that there is ambiguity, but
  # that is very unlikely, because of temp id (see #get_memory_id) big size.
  # Also +conditions+ for finding is accpeted as well.
  # First method checks if there is memory record with given +memory_id+ (see #has_memory_container?)
  # and then find files from memory (see #find_in_memory) or existing files (see #find_existing).
  def self.find_current_files class_name,memory_id,conditions=[]
    if self.has_memory_container?(memory_id)
      self.find_in_memory(memory_id,conditions)
    else
      self.find_existing(class_name,memory_id,conditions)
    end
  end

  # Very similar to #find_current_files but allow Array of +ids+ to be passed for filtering.
  # ====Example
  #     Media::ImageFile.find_files_from_ids("User",1,[33,34,35])
  #     #=> Return only images with given ids from 33 to 35 for User with ID 1.
  def self.find_files_from_ids(class_name,memory_id,ids=[])
    conditions=["#{self.has_memory_container?(memory_id) ? "#{Media::MediaFileTempMemory.table_name}.media_file_id IN (?)" : "#{self.table_name}.id"} IN (?)",ids]
    self.find_current_files(class_name,memory_id,conditions)
  end

  #End of new functions added when changed to media namespace
  # Create new file from given params and add related object to it or
  # only object class name if object not exist yet.
  # Accpted params:
  # * <tt>:parent_id</tt> - ID of existing record (Optional).
  # * <tt>:parent</tt> - Parent object class name for related object.
  # * <tt>:media</tt> - Media name, has no any difference when used separately of controllers:
  #   * <tt>:name</tt> - File name, always need to be placed under params[params[:media]].
  # ====Example
  #     Media::ImageFile.new_file(:parent_id=>1, :parent=>"user", :media=>"image",:image=>{:name=>"avatar.jpeg"})
  #     #=> Create image with name avatar.jpeg for User with ID 1 if user exists or image for User without any ID.
  def self.new_file(params)
    file=self.new()
    polymorphic_name=media_get_polymorphic_name
    if params[:parent_id] && parent=params[:parent].camelize.constantize.find_by_id(params[:parent_id])
      file.send("#{polymorphic_name}=",parent)
    else
      file.send("#{polymorphic_name}_type=",params[:parent].camelize)
    end
    file.name=params[params[:media].to_sym][:name] if params[params[:media].to_sym]
    file
  end

  # Remove all media files for current #Media class that is older than one day
  # ant that doesn't have parent ID assigned with it.
  # And also removes all references to that files from #Media::MediaFileTempMemory table.
  # For details of removing temp files see #delete_all.
  # Is used in #update_memorized_files and can be used in Cron tasks.
  def self.clear_temp_files
    polym_name=media_get_polymorphic_name
    memory_ids=[]
    self.find(:all,:conditions=>["#{polym_name}_id IS NULL AND created_at<=?",1.day.ago]).each{|f|
      memory_ids<<f.id
      f.destroy
    }
    Media::MediaFileTempMemory.delete_all(["media_file_id IN (?)",memory_ids]) unless memory_ids.empty?
  end

  # When +parent+ object is created and it has real record ID then this method need
  # to be called to update media files linked with that object. For that old +memory_id+
  # need to be provided to this method.
  # Method goes through all files that was kept in memory and update parent ids of them to
  # new one +parent+ id. Also refresh +parent+ object and clear temp files (see #clear_temp_files)
  # that is done because this method is triggered every time than new object is created via #Managed
  # built in method create. For details of trigger see Lolita::Multimedia::InstanceMethods#update_multimedia.
  def self.update_memorized_files(memory_id,parent)
    poly_name=self.media_get_polymorphic_name
    result=self.find_in_memory(memory_id).collect{|obj|
      obj.update_attributes!(:"#{poly_name}_type"=>parent.class.base_class.to_s,:"#{poly_name}_id"=>parent.id)
      self.delete_file_from_memory(obj.id)
      obj
    }
    parent.class.assing_polymorphic_result_to_object(parent,result,poly_name.to_sym) if memory_id.to_s.size>0
    self.clear_temp_files
  end

end
