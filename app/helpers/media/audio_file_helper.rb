module Media::AudioFileHelper
  def audio_extensions
    UploadColumn.audio_extensions.collect{|t| "*.#{t};"}.join
  end

end
