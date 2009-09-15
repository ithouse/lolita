module Media::GoogleMapHelper
  def lolita_google_map_tab(options,tab)
    p_options={
      :read_only=>@read_only,
      :lat=>Media::GoogleMap.collect_lat(@object),
      :lng=>Media::GoogleMap.collect_lng(@object)
    }.merge(tab.delete_if{|v,k| k==:type}).merge(default_media_tab_options(tab))
    unless options[:in_form]
      render :partial=>"/media/#{tab[:media]}/container", :object=>p_options
    else
      render :partial=>"/media/#{tab[:media]}/in_form", :object=>p_options
    end
  end

  def public_google_map_configuration(conf={})
    if conf[:object]
      locations=Media::GoogleMap.collect_coords(conf[:object])
      conf[:lat]=locations[:lat]
      conf[:lng]=locations[:lng]
    end
    conf[:id_prefix]="public_map"
    conf[:read_only]=true
    conf
  end
end
