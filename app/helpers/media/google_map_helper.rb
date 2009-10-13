module Media::GoogleMapHelper

  #Render Google map.
  #
  # ====Options
  #
  # <tt>:unique_id</tt> - unique Integer or String value.<br/>
  # <tt>:class_name</tt> - optional, map container html class name, if with google-map is not enough.<br/>
  # <tt>:lat</tt> - Array with latitudes, if <tt>:object</tt> passed then <tt>:lat</tt> and <tt>:lng</tt> will be overwritten.<br/>
  # <tt>:lng</tt> - Array with longitudes.<br/>
  # <tt>:width</tt> - map container with in px, default 600.<br/>
  # <tt>:height</tt> - map container height in px, default 400.<br/>
  # <tt>:object</tt> - ActiveRecord object that refrers to Media::GoogleMap object.<br/>
  # <tt>:zoom</tt> - level of magnification.<br/>
  # <tt>:map_prefix</tt> - map container HTML id prefix (:map_prefix=>"contacts_map").
  #
  # ====Example
  #
  #   # Renders map from object with one or more GoogleMap points
  #   public_google_map :object=>@my_map
  #
  #   # Renders map with given locations and size
  #   public_google_map :lat=>[12.094323,14.123069],:lng=>[30.123432,50.124543],:width=>250,:height=>150
  #
  def public_google_map(options={})
    options[:unique_id]||=(Time.now.to_f*1000).to_i
    render :partial=>"media/google_map/public_container",:object=>options
  end

  def lolita_google_map_tab(options,tab)
    p_options=(tab.delete_if{|v,k| k==:type}).merge(default_media_tab_options(tab)).merge({
        :read_only=>@read_only,
        :zoom=>15,
        :center_marker=>true,
        :lat=>Media::GoogleMap.collect_lat(@object),
        :lng=>Media::GoogleMap.collect_lng(@object),
        :single=>Media::GoogleMap.belongs_to_one?(@object),
      }) # last options are important
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
    else
      conf[:lat]||=[]
      conf[:lng]||=[]
    end
    conf[:map_prefix]||="public_map"
    conf[:read_only]=true
    conf[:include_js]=true if conf[:include_js].nil?
    conf=conf.delete_if{|k,v| [:object].include?(k)}
    raise "Unique ID not specified!" if conf[:unique_id].to_s.size==0
    conf
  end

  def include_google_map_js
    #%(<script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false&key=#{Lolita.config.google(:maps_key)}"></script>)
    "<script type=\"text/javascript\" src=\"http://maps.google.com/maps?file=api&amp;v=3&amp;key=#{Lolita.config.google :maps_key}\"></script>"
  end
end
