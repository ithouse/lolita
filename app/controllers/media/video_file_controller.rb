class Media::VideoFileController < Media::ControllerFileBase
  allow :all=>[:destroy,:show,:add_picture,:remove_picture,:new_create,:refresh]

  def add_picture
    if params[:video_file] && video=VideoFile.find_by_id(params[:video_file][:id])
      picture_attributes=params[:video_file].delete_if{|key,value|
        ![:picture,:picture_temp].include?(key.to_sym)
      }
      begin
        picture=Media::ImageFile.new(picture_attributes)
        video.picture=picture
        picture.save!
        video.save!
        render :partial=>"only_player",:locals=>{:video=>video}
      rescue
        render :text=>"#{t(:"simple words.error")}! #{t(:"javascript.error dialog text")}",:status=>404
      end
      
    else
      render :text=>"#{t(:"simple words.error")}! #{t(:"javascript.error dialog text")}", :status=>404
    end
  end

  def remove_picture
    if params[:id] && video=VideoFile.find_by_id(params[:id])
      begin
        video.picture.destroy
        video.picture=nil
        render :partial=>"only_player",:locals=>{:video=>video}
      rescue
        render :text=>"#{t(:"simple words.error")}! #{t(:"javascript.error dialog text")}", :status=>404
      end
      
    else
      render :text=>"#{t(:"simple words.error")}! #{t(:"javascript.error dialog text")}", :status=>404
    end
  end
end
