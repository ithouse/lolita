class Admin::AccessController < Managed
  allow Admin::Role.admin
  access_control :exclude=>[:edit,:update,:new,:create,:destroy]
  managed_before_list :collect_all_accessable_classes
  def index
    redirect_to :action=>:list, :is_ajax=>params[:is_ajax]
  end
 
  def change_permission
    if params[:permissions] && params[:access] && params[:role]
      if access=Admin::Access.find_by_id(params[:access])
        access.can_with_role_do(params[:role],params[:permissions])
      end
    end
    render :text=>'OK'
  end
  
  def remove_all_permission
    if  params[:access] && params[:role]
      if access=Admin::Access.find_by_id(params[:access])
        access.can_nothing_with_role(params[:role])
      end
    end
    render :text=>'OK'
  end
  
  def add_role
    if params[:role] && params[:access] 
      if access=Admin::Access.find_by_id(params[:access])
        access.has_role(params[:role])
        access.can_all_with_role(params[:role])
      end
    end
    render :text=>'OK'
  end
  
  def remove_role
    if params[:role] and params[:access]
      if Admin::Access.exists? params[:access]
        access=Admin::Access.find(params[:access])
        access.has_no_role( params[:role])
      end
    end
    render :text=>'OK'
  end
  
  def all_accesses
    Admin::Access.collect_all
    render :partial=>'all_accesses', :locals=>{:role=>Admin::Role.find_by_id(params[:id])}, :layout=>false
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
