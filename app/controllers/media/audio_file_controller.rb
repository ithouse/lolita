# Handle Media::AudioFile records.
# Also allow to add and remove first picture for audio player.
class Media::AudioFileController < Media::ControllerFileBase
  allow :all=>[:destroy,:show,:add_picture,:remove_picture,:new_create,:refresh]

  # Add picture for audio file with given id and return new player with uploaded picture or error message.
  # ====Example
  #  params #=> {:audio_file=>{:id=>1,:picture=>{:picture=>FileData,:picture_temp=>FileData}}
  def add_picture
    if params[:audio_file] && audio=Media::AudioFile.find_by_id(params[:audio_file][:id])
      picture_attributes=params[:audio_file].delete_if{|key,value|
        ![:picture,:picture_temp].include?(key.to_sym)
      }
      begin
        picture=Media::ImageFile.new(picture_attributes)
        audio.picture=picture
        picture.save!
        audio.save!
        render :partial=>"only_player",:locals=>{:audio=>audio}
      rescue
        render :text=>"#{t(:"simple words.error")}! #{t(:"javascript.error dialog text")}",:status=>404
      end

    else
      render :text=>"#{t(:"simple words.error")}! #{t(:"javascript.error dialog text")}", :status=>404
    end
  end

  # Remove picture from audio file with given :id and render player without picture or error message.
  def remove_picture
    if params[:id] && audio=Media::AudioFile.find_by_id(params[:id])
      begin
        audio.picture.destroy
        audio.picture=nil
        render :partial=>"only_player",:locals=>{:audio=>audio}
      rescue
        render :text=>"#{t(:"simple words.error")}! #{t(:"javascript.error dialog text")}", :status=>404
      end

    else
      render :text=>"#{t(:"simple words.error")}! #{t(:"javascript.error dialog text")}", :status=>404
    end
  end
end
