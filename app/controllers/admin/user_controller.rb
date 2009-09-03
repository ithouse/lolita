class Admin::UserController < Managed
  allow Admin::Role.admin,:all=>[:edit_self], :public=>[:login,:logout,:forgot_password]
  #menu_actions :system=>{:view_log=>I18n.t(:"user.log")}
  
  def index
    if params[:id]
      redirect_to :action=>'edit', :id=>params[:id], :is_ajax=>params[:is_ajax]
    else
      redirect_to :action=>'list', :is_ajax=>params[:is_ajax]
    end
  end
  
  def login
    flash[:error]=nil
    if request.post?
      if user = Admin::SystemUser.authenticate(params[:login], params[:password])
        update_token(user)
        register_user_in_session user
        redirect_to(:controller=>Admin::Configuration.get_value_by_name('start_page'))
      else
        if params[:password] && params[:login]
          flash[:error]=I18n.t(:"errors.unknown_user")
        end
        render :layout=>"admin/login"
      end
    else
      if logged_in?
        update_token()
        #TODO: šeit jāiet uz admin sadaļu ja system/login
        redirect_to(:controller=>Admin::Configuration.get_value_by_name('start_page'),:is_ajax=>params[:is_ajax])
      else
        render :layout=>"admin/login"#TODO jāpadomā ko darīt ja lapai nav paredzēta publiskā daļa
      end
    end
  end
  
  def logout
    if logged_in? 
      self.current_user.forget_me 
      # cookies.delete :auth_token
      reset_session
      flash[:notice] = I18n.t(:"flash.logout success")
    end
    redirect_to :action=>:login
  end
  
  def edit_self
    if session[:user] && session[:user].is_a?(Admin::SystemUser) && session[:user].is_real_user?
      @user=Admin::SystemUser.find_by_id(params[:id])
      if @user && @user==session[:user] 
        if request.post? 
          if params[:user][:old_pass]  && @user.authenticated?(params[:user][:old_pass])
            params[:user].delete(:old_pass)
            if @user.update_attributes(params[:user]) && @user.errors.size<1
              register_user_in_session @user
              redirect_to :controller=>Admin::Configuration.get_value_by_name("start_page") || "/", :is_ajax=>params[:is_ajax]
              return
            end
          else
            @user.errors.add(I18n.t(:"user.old password"),I18n.t(:"errors.not_correct_female"))
          end
        end
        render :layout=>params[:is_ajax] ? false : "cms/default"
      else
        to_login_screen
      end
    else
      to_login_screen
    end
  end
  
  def forgot_password
    flash[:error]=nil
    redirect_to :action=>"login" if session[:user]
    @user={}
    @errors={}
    if request.post? && params[:user] && (is_human=HumanControl.check(params[:human_control]))
      @user=Admin::User.find_by_login(params[:user][:login])
      if @user && !@user.is_e_user?
        temp_pass=Admin::User.temp_password
        @user.update_attributes(
          :password=>temp_pass,
          :password_confirmation=>temp_pass,
          :reset_password_expires_at=>Time.now()+(3*60*60*24)
        )
        body_data={}
        body_data[:header]="#{I18n.t(:"system_user.form.title")} #{Admin::Configuration.get_value_by_name("system_title")}"
        body_data[:a]={:title=>I18n.t(:"system_user.form.name"),:value=>@user.login}
        body_data[:b]={:title=>I18n.t(:"system_user.form.password"),:value=>temp_pass}
        #body_data[:c]={:title=>"",:value=>"Pieteikšanās sistēmā jāveic 3 dienu laikā!"}
        email_sent(@user.email,"#{I18n.t(:"system_user.form.title")} #{Admin::Configuration.get_value_by_name("system_title")}",body_data)
        redirect_to :action=>"login"
      else
        flash[:error]= I18n.t(:"flash.user not found")
        render :layout=>"admin/public"
      end
    else
      if request.post? && !is_human
        flash[:error]= I18n.t(:"flash.human controll not correct")
      end
      render :layout=>"admin/public"
    end
  end
  
  def add_role
    if params[:role] and params[:user]
      user=Admin::SystemUser.find_by_id(params[:user])
      user.has_role(params[:role]) if user
    end
    render :text=>"OK"
  end
  
  def remove_role
    if params[:role] and params[:user]
      user=Admin::SystemUser.find(params[:user])
      user.has_no_role(params[:role]) if user
    end
    render :text=>'OK'
  end
  
  def all_users
    @role = Admin::Role.find(params[:id]) if Admin::Role.exists?(params[:id])
    render :partial=>'all_users', :locals=>{:role=>@role}
  end

  def view_log
    @text=Admin::User.user_activities
  end

  def clear_log
    Admin::User.clear_user_activities
    redirect_to :action=>"view_log"
  end
  private

  def update_token(user=nil)
    if Lolita.config.multi_domain_portal && !is_local_request?
      token=Admin::Token.find_by_token(cookies[:sso_token])
      if token
        if user
          token.update_attributes!(:user=>user,:uri=>url_for(Admin::Configuration.get_value_by_name('start_page')))
        else
          token.update_attributes!(:uri=>url_for(Admin::Configuration.get_value_by_name('start_page')))
        end
      end
    end
  end
  def before_destroy
    if Admin::SystemUser.find_by_id(params[:id])==session[:user]
      @my_params.delete(:id)
    end
  end
  
  def before_list
    @active_user=Admin::User.find_by_id(params[:id])
  end

  def config
    {
      :object=>"Admin::SystemUser",
      :tabs=>[
        {:type=>:content,:in_form=>true,:opened=>true,:fields=>:default},
        {:type=>:pictures,:in_form=>true,:single=>true}
      ],
      :list=>{
        :options=>[:edit,:destroy],
        :per_page=>100
      },
      :fields=>[
        {:type=>:text,:field=>:login,:html=>{:maxlength=>255}},
        {:type=>:text,:field=>:email,:html=>{:maxlength=>255}},
        {:type=>:password,:field=>:password,:html=>{:maxlength=>40}},
        {:type=>:password,:field=>:password_confirmation,:html=>{:maxlength=>40}}
      ]
    }
  end
  
  def register_user_in_session user
    reset_session
    set_current_user user
  end
  def email_sent(email,title,data)
    RequestMailer::deliver_mail(email,"#{title}",data)
  end
  def get_users
    return Admin::User.find(:all)
  end
end
