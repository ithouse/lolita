module Media::VideoFileHelper
  def video_extensions
    UploadColumn.video_extensions.collect{|t| "*.#{t};"}.join
  end
end
