module MediaHelper
  def new_file_path_with_session_information media
    session_key = ActionController::Base.session_options[:key]
    url_for(:controller => media, :action => :new_create, session_key => cookies[session_key], request_forgery_protection_token => form_authenticity_token)
  end

  def image_extensions
    # used in swfuploader to get types
    UploadColumn.image_extensions.collect{|t| "*.#{t};"}.join
  end

  def audio_extensions
    UploadColumn.audio_extensions.collect{|t| "*.#{t};"}.join
  end

  def video_extensions
    UploadColumn.video_extensions.collect{|t| "*.#{t};"}.join
  end

  def file_types_description media
    # returns browse window file types name
    case media
      when "image_file"
        return I18n.t("lolita.media.images")
      when "audio_file"
        return I18n.t("lolita.media.audios")
      when "video_file"
        return I18n.t("lolita.media.videos")
      else
        return I18n.t("lolita.media.all")
    end
  end
end
