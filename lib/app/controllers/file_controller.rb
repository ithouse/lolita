class FileController < MediaBase
  allow :all=>[:create,:destroy,:show,:ajax_container,:refresh,:new_create],:public=>[:download]
  def download
    error=false
    if params[:file] && params[:file].size>0 && file=FileItem.find_by_name(params[:file])
      public=(file.user_id.to_i==0 && file.role_id.to_i==0 && file.is_public)
      if !file && !public && !(user_permission?(file.user_id) || role_permission?(file.role_id))
        error=true
      end
    else
      error=true
    end
    if error
      render :text=>'Fails nav pieejams!'.t,:status=>400
    else
      send_file RAILS_ROOT+'/public'+file.name.url, :type => file.name_mime_type
    end
  end

  def ajax_container
    my_id=params[:my_id] || nil
    render :partial=>'ajax_container', :object=>{:parent=>parent_name,:parent_id=>parent,:single=>single?,:my_id=>my_id}
  end
  
  private

  def user_permission? user_id
    return false unless session[:user]
    user=User.find(user_id) if User.exists?(user_id)
    if session[:user].has_role(Admin::Role.admin) || session[:user]==user
      true
    else
      false
    end
  end
  def role_permission? role_id
    return false unless session[:user]
    role=Role.find(role_id) if Role.exists?(role_id)
    if session[:user].has_role(Admin::Role.admin) || session[:user].has_role?(role.name)
      true
    else
      false
    end
  end
 
end
