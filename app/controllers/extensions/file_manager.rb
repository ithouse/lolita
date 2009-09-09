module Extensions::FileManager
  
  def update_uploaded_files(object,id)
    Media::FileBase.all_media_names.each{|media|
      "Media::#{"#{media}_file".camelize}".constantize.update_memorized_files(id,object)
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
