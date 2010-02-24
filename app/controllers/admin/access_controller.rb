class Admin::AccessController < Managed
  allow Admin::Role.admin
  access_control :exclude=>[:edit,:update,:new,:create,:destroy]
  managed_before_list :collect_all_accessable_classes

  # Return all accesses for _role_ view, render whole list action or only render
  # partial, if request is Ajax request.
  # Redirect to login screen when no role with given _role_id_ was found.
  def index
    if @role = Admin::Role.find_by_id(params[:role_id])
      if request.xhr?
        render :partial=>'admin/role/tabs', :locals=>{:role=>@role,:active_tab=>:accesses,:active_role=>@role}
      else
        redirect_to list_access_url(@role.id,:tab=>:accesses)
      end
    else
      request.xhr? ? render(:nothing=>true) : redirect_to(login_users)
    end
  end

  # Render all roles for current _access_, when Ajax request then render
  # all *list* action.
  def current_roles
    if request.xhr?
      render :partial=>'index',
        :locals=>{:access=>Admin::Access.find_by_id(params[:id])},
        :layout=>false
    else
      list
    end
  end

  # Add or remove some of permissions for access-role relations.
  # Receive following params:
  # * <tt>:id</tt> - Access ID
  # * <tt>:role_id</tt> - Role ID
  # * <tt>:permissions</tt> - Hash where key is permission name and value is 0 or 1.
  def change
    if access=Admin::Access.find_by_id(params[:id])
      access.can_with_role_do(params[:role_id].to_i,params[:permissions])
    end
    render :nothing=>true, :status=> access ? 200 : 404
  end

  # Create access-role relation and add all permissions to that relation link.
  def add
    if access=Admin::Access.find_by_id(params[:id])
      access.has_role(params[:role_id].to_i)
      access.can_all_with_role(params[:role_id].to_i)
    end
    render :nothing=>true, :status=> access ? 200 : 404
  end

  # Remove access-role relation from or, in other words, remove role from
  # access roles collections.
  def remove
    if access=Admin::Access.find_by_id(params[:id])
      access.has_no_role(params[:role_id].to_i)
    end
    render :nothing=>true, :status=> access ? 200 : 404
  end
 
  private 

  def collect_all_accessable_classes
    if !@accesses
      Admin::Access.collect_all
    end
    @accesses=Admin::Access.find(:all)
    if params[:id]
      @active_access=Admin::Access.find_by_id(params[:id])
      @active_name=@active_access.name if @active_access
    end
  end

  def config
    {
      :list=>{
        :per_page=>100
      }
    }
  end
end
