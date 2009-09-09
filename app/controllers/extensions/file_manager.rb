module Extensions::FileManager
  
  def update_uploaded_files(object,id)
    Media::FileBase.all_media_names.each{|media|
      klass="Media::#{"#{media}".camelize}".constantize
      klass.update_memorized_files(id,object) if klass.respond_to?(:update_memorized_files)
    }
  end
  
  private

  def has_file_id?
    params[:temp_file_id].to_i>0
  end
  def file_id
    params[:temp_file_id] || nil
  end
end
