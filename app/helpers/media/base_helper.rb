module Media::BaseHelper
  Find.find(File.dirname(__FILE__)) do |path|
    if File.basename(__FILE__,".rb")!=File.basename(path,".rb") && !File.directory?(path)
      include "Media::#{File.basename(path,".rb").camelize}".constantize
    end
  end

  #Each module can have following method implemented to work with managed
  # * lolita_[media name]_tab(options,tab) - can be used to render different
  #   partial form from default, and to render fields in default form when [:in_form]
  #   options is passed. See #default_lolita_media_tab
  def default_media_tab_options tab
    {
      :media=>tab[:media],
      :parent=>@config[:object_name].camelize.constantize.base_class.to_s.underscore, #to make polymorphic class correct
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
      render :partial=>'/media/container', :object=>{
        :read_only=>@read_only
      }.merge(tab.delete_if{|v,k| k==:type}).merge(default_media_tab_options(tab))
    end
  end

  def get_class_name_from_media(media)
    "Media::#{media.to_s.camelize}".constantize
  end
end