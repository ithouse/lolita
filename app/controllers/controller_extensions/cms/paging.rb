# Conduit between #Managed and #Lolita::Paginator
module ControllerExtensions::Cms::Paging

  private
  # Send params to Cms::Base#paginate.
  def paging (parent,options={})
   # parent=options[:object] ? (options[:object].camelize.constantize) : parent
    session_name=current_session_name
    session[session_name]={} unless session[session_name]
    session[session_name].each{|key,value| 
      options[key]=value unless options.has_key?(key)
    }
    page=parent.paginate(options)
    
    params[:sort_column]=page.simple_sort_column
    params[:sort_direction]=page.sort_direction
    
    session[session_name][:sort_column]=page.simple_sort_column
    session[session_name][:sort_direction]=page.sort_direction
    session[session_name][:page]=page.current
    session[session_name][:ferret_filter]=page.ferret_filter || page.simple_filter
    page
  end

end
