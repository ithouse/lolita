class Admin::RoleController < Managed
  allow Admin::Role.admin
  managed_before_list :set_active_role

  # Add _role_ for _user_. Necessary params
  # * <tt>:user_id</tt> - user ID
  # * <tt>:id</tt> - role ID
  def add
    user=Admin::User.find_unknown_user(:first,:id=>params[:user_id])
    user.has_role(params[:id].to_i) if user
    render :nothing=>true, :status=>user ? 200 : 404
  end

  # Remove _role_ from _user_ roles. Necessary params
  # * <tt>:user_id</tt> - user ID
  # * <tt>:id</tt> - role ID
  def remove
    user=Admin::User.find_unknown_user(:first,:id=>params[:user_id])
    user.has_no_role(params[:id].to_i) if user
    render :nothing=>true, :status=>user ? 200 : 404
  end

  # Before edit check if _role_ is not built in.
  # Built in roles cannot been edited, updated or destroyed.
  def edit
    can_change? ? super : back_to_list
  end

  # See #edit.
  def update
    can_change? ? super : back_to_list
  end

  # See #edit.
  def destroy
    can_change? ? super : back_to_list
  end

  private

  def set_active_role
    @active_tab=params[:tab].to_s=="accesses" ? :accesses : :users
    @active_role=Admin::Role.find_by_id(params[:id])
  end
  
  def back_to_list
    redirect_to :action=>:list, :is_ajax=>request.xhr?
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
