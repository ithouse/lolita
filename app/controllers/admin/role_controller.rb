class Admin::RoleController < Managed
  allow Admin::Role.admin
  def index
    if get_id
      redirect_to :action=>'edit', :id=>params[:id]
    else
      redirect_to :action=>'list', :is_ajax=>params[:is_ajax]
    end
  end

  def edit
    can_change? ? super : back_to_list
  end

  def update
    can_change? ? super : back_to_list
  end
  
  def destroy
    can_change? ? super : back_to_list
  end
  
  def all_roles
    render :partial=>'all_roles',:locals=>{:user=>Admin::User.find_by_id(params[:id])}, :layout=>false
  end
  
  def all_access_roles
    render :partial=>'all_access_roles', :locals=>{:access=>Admin::Access.find_by_id(params[:id])},:layout=>false
  end

  private

  def before_list
    @show_users=(params[:access] ? false :true)
    @active_role=Admin::Role.find_by_id(params[:id])
  end
  
  def back_to_list
    redirect_to :action=>:list, :is_ajax=>params[:is_ajax]
  end

  def can_change?
    role=Admin::Role.find_by_id(params[:id])
    role && !role.built_in
  end
  
  def config
    {
      :tabs=>[{:type=>:content,:in_form=>true,:opened=>true,:fields=>:default}],
      :list=>{
        :options=>[:edit,:destroy],
        :per_page=>100
      },
      :fields=>[
        {:type=>:text,:field=>:name,:html=>{:maxlength=>255}}
      ]
    }
  end
end
