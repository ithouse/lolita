module Extensions::FilterHelper

  def self_filter_value
    session[current_session_name][:ferret_filter]
  end
  
  def simple_filter options={}
    render :partial=>"/cms/simple_filter", :object=>options
  end
  def simple_filter_options options={}
    default_options={
      :action=>'list',
      :container=>'#content'
    }
    default_options.merge(options)
  end

  def parent_filter controller=nil
    parents=@config[:list][:parent_filter].is_a?(Array) ? @config[:list][:parent_filter] : @config[:parents]
    object=(controller || params[:controller]).camelize.constantize
    object.parent_data_collector(object.parent_class_collector(parents)) do |key,parent,data_array|
      switch="simple_yui_request(this,
          {
            url:'#{url_for(:controller=>controller || params[:controller],:action=>params[:action])}',
            container:'form_list',
            params:{paging:true},
            method: 'GET',
            before:'config.params.#{key}=object.value',
            loading:true
          }
        )"
      yield switch,options_for_select([["-#{t(:"simple words.choose")} #{table_title(parent.underscore).to_s.downcase}-",-1]]+data_array,params[key].to_i)
    end
  end
end