#require 'ffmpeg'
class AudioFileController < MediaBase
  allow :all=>[:create,:destroy,:show,:add_picture,:remove_picture,:new_create,:refresh]

  def shot
#    file=FFMPEG.video_screenshot(:input=>"#{RAILS_ROOT}/public/swf/video.flv",:format=>"png",:stream=>true)
#    FileItem.create_file("public","asdf.png",file)
#    send_data(file,
#      :disposition => 'inline',
#      :type => 'image/png'
#    )
    #asdf
    #        headers['Content-Type'] = "image/png"
    #       render :text=>file
  end

  def add_picture
    if params[:audio_file] && audio=AudioFile.find_by_id(params[:audio_file][:id])
      picture_attributes=params[:audio_file].delete_if{|key,value|
        ![:picture,:picture_temp].include?(key.to_sym)
      }
      begin
        picture=Picture.new(picture_attributes)
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

  def remove_picture
    if params[:id] && audio=AudioFile.find_by_id(params[:id])
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
