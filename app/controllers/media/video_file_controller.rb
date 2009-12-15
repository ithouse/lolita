# Handle #Media::VideoFile records and add methods for adding and removing image for video player.
class Media::VideoFileController < Media::ControllerFileBase
  allow :all=>[:destroy,:show,:add_picture,:remove_picture,:new_create,:refresh]

  # Add picture for video file with given id and return new player with uploaded picture or error message.
  # ====Example
  #  params #=> {:video_file=>{:id=>1,:picture=>{:picture=>FileData,:picture_temp=>FileData}}
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

  # Remove picture from video file with given :id and render player without picture or error message.
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
