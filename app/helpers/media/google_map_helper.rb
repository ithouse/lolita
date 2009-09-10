module Media::GoogleMapHelper
  def lolita_google_map_tab(options,tab)
    unless options[:in_form]
      render :partial=>"/media/#{tab[:media]}/container", :object=>{
        :read_only=>@read_only
      }.merge(tab.delete_if{|v,k| k==:type}).merge(default_media_tab_options(tab))
    end
  end
end
