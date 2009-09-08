module Media::BaseHelper
  Find.find(File.dirname(__FILE__)) do |path|
    if File.basename(__FILE__,".rb")!=File.basename(path,".rb") && !File.directory?(path)
      include "Media::#{File.basename(path,".rb").camelize}".constantize
    end
  end

  def default_media_tab_options tab
    {
      :media=>"#{tab[:media]}_file",
      :parent=>@config[:object_name],
      :tempid=>(params[:action]!="update"),
      :parent_id=>(params[:action]!="update")? @new_object_id : @object.id
    }
  end

  def tab_default_form_params
    %(<input type="hidden" value="#{@new_object_id}" name="temp_file_id" />)
  end

  def default_lolita_media_tab(options,tab)
    if options[:in_form]
      tab_default_form_params
    elsif !options[:in_form]
      render :partial=>'/media/new_upload_container', :object=>{
        :read_only=>@read_only
      }.merge(tab.delete_if{|v,k| k==:type}).merge(default_media_tab_options(tab))
    end
  end
  
  def file_source file
    if file and !file.name.nil?
      return file.name.url
    end
  end

  def get_class_name_from_media(media)
    "Media::#{media.to_s.camelize}".constantize
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
    self.send("#{media.gsub(/_.+$/,"")}_extensions")
  end

  def file_types_description media
    I18n.t("lolita.media.#{media.gsub(/_.+$/,"")}")
  end
end