module Extensions::FileAndPictureManager
  def update_uploaded_pictures(object,id)
    session_parent_id = session_id(id)
    params[:id]=session_parent_id
    ses_arr=session[:uploaded_pictures][session_parent_id] if session[:uploaded_pictures] && session[:uploaded_pictures][session_parent_id]
    if ses_arr.is_a?(Array) && ses_arr.size>0
      result_pictures=Picture.update_temp_pictures(object,ses_arr)
      session[:uploaded_pictures].delete(session_parent_id)
    end
    Picture.clear_temp_pictures()
    blank_pictures_count=Picture.count(:all,:conditions=>["pictureable_type IS NULL AND pictureable_id IS NULL AND id IN (?)",all_temp_ids(session[:uploaded_pictures])])
    session[:uploaded_pictures].clear if session[:uploaded_pictures] && blank_pictures_count==0
    object.class.assing_polymorphic_result_to_object(object,result_pictures || [],:pictureable)
  end
  
  def update_uploaded_files(object,id)
    {:uploaded_video_files=>["video",VideoFile],:uploaded_audio_files=>["audio",AudioFile],:uploaded_files=>["fileable",FileItem]}.each{|media,class_obj|
      session_parent_id = session_id(id)
      params[:id]=session_parent_id
      result_files=[]
      ses_arr=session[media][session_parent_id] if session[media] && session[media][session_parent_id]
      if ses_arr.is_a?(Array) && ses_arr.size>0
        result_files=class_obj[1].update_temp_files(object,ses_arr,class_obj[0].to_sym)
        session[media].delete(session_parent_id)
      end
      blank_file_count=class_obj[1].count(:all,:conditions=>["#{class_obj.first}_type IS NULL AND #{class_obj.first}_id IS NULL AND id IN (?)",all_temp_ids(session[media])])
      class_obj[1].clear_temp_files()
      session[media].clear if session[media] && blank_file_count==0
      object.class.assing_polymorphic_result_to_object(object,result_files,class_obj[0].to_sym)
    }
  end
  
  private

  def session_id(id)
    ("t"+id.to_s).to_sym
  end
  
  def all_temp_ids arr=[]
    result=[]
    arr.each{|key,values|
      result=result+values
    } if arr.is_a?(Array)
    result
  end
  
  def has_file_id?
    params[:temp_file_id].to_i>0
  end
  def file_id
    params[:temp_file_id] || nil
  end
  def has_picture_id?
    params[:temp_picture_id].to_i>0
  end
  def picture_id
    params[:temp_picture_id] || get_temp_id
  end
 
end
