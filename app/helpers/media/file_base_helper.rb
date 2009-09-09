module Media::FileBaseHelper
  def file_source file
    if file and !file.name.nil?
      return file.name.url
    end
  end

  def get_all_parent_files(options={})
    class_name=get_class_name_from_media(options[:media])
    files=class_name.find_current_files(options[:parent],options[:parent_id])
    yield files
  end

  def file_extensions_description cfg={}
    result=file_types_description(cfg[:media])
    ext=file_extensions(cfg[:media])
    "#{result} (#{ext})"
  end

  def file_extensions media
    self.send("#{media}_extensions")
  end

  def file_types_description media
    I18n.t("lolita.media.#{media}")
  end
end