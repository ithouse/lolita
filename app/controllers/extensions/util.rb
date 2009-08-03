module Extensions::Util

  def current_session_name
    params[:controller].gsub(/^\//,"").gsub("/","_").to_sym
  end

  def month_names(options={})
    months=[
      t(:"months.january"),t(:"months.february"),
      t(:"months.march"),t(:"months.april"),
      t(:"months.may"),t(:"months.june"),
      t(:"months.july"),t(:"months.august"),
      t(:"months.september"),t(:"months.october"),
      t(:"months.november"),t(:"months.december"),
    ]
    months.collect!{|month| month.capitalize} if options[:capitalize]
    months
  end
  
  def get_temp_id
    (("%10.7f" % rand).to_f*10000000).to_i
  end
  private 
  
  def menu_actions
    [] 
  end
    
  def controller_in_parts controller=params[:controller]
    p=controller.to_s.split(/\//)
    p.shift if p[0].size<1
    p
  end
  def get_id(object=nil,controller=nil)
    object ? (object.is_a?(Symbol) ? get_url_for(object,controller) : make_url_for(object)) : get_url_for
  end

  def make_url_for(object)
    if meta_data=MetaData.find_by_object(object)
      meta_data.url
    else
      object.id
    end
  end

  def get_url_for(name=nil,controller=nil)
    name||=:id
    if params[name] && (params[name].is_a?(Integer) || (params[name].to_i.to_s.size==params[name].to_s.size))
      params[name].to_i
    else
      meta_data=MetaData.by_metaable(params[name]||params[:meta_url],controller || params[:controller])
      meta_data.metaable_id if meta_data
    end
  end
end

