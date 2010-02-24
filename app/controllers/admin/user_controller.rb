class Admin::UserController < Managed
  include SimpleCaptcha::ControllerHelpers
  allow Admin::Role.admin,:all=>[:edit_self], :public=>[:login,:logout,:forgot_password,:change_password]
  managed_before_list :set_active_user
  # Login <em>Admin::SystemUser</em> into <b>Lolita's</b> administrative side.
  #
  # If request is _POST_ then do authentication, otherwise redirect to start page
  # indicated in configuration :system->:start_page_url if logged in, or render loging form
  # if not logged in.
  #
  # When authentication is successful #update_token and #register_user_in_session is called.
  def login
    flash[:error]=nil
    if request.post?
      if user = Admin::SystemUser.authenticate(params[:login], params[:password],:none)
        register_user_in_session user
        redirect_to(Lolita.config.system(:start_page_url))
      else
        if params[:password] && params[:login]
          flash[:error]=I18n.t(:"errors.unknown_user")
        end
        render :layout=>"admin/login"
      end
    else
      if logged_in?
        #TODO: šeit jāiet uz admin sadaļu ja system/login
        redirect_to(Lolita.config.system(:start_page_url))
      else
        render :layout=>"admin/login"#TODO jāpadomā ko darīt ja lapai nav paredzēta publiskā daļa
      end
    end
  end

  # Logout user from <b>Lolita's</b> administrative side.
  # Session is cleared and <em>remember me</em> deleted, and next time automatic login
  # will not be performed. Finaly redirects to #login action.
  def logout
    if logged_in? 
      self.current_user.forget_me 
      reset_session
      flash[:notice] = I18n.t(:"flash.logout success")
    end
    redirect_to :action=>:login
  end
  
  # ====Deprecated
  # Any system user can edit their own password. This method allow to do that.
  def edit_self
    if session[:user] && session[:user].is_a?(Admin::SystemUser) && session[:user].is_real_user?
      @user=Admin::SystemUser.find_by_id(params[:id])
      if @user && @user==session[:user] 
        if request.post? 
          if params[:user][:old_pass]  && @user.authenticated?(params[:user][:old_pass])
            params[:user].delete(:old_pass)
            if @user.update_attributes(params[:user]) && @user.errors.size<1
              register_user_in_session @user
              redirect_to Lolita.config.system(:start_page_url)
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

  # Render <em>Forgot password</em> form and send e-mail with new password.
  def forgot_password
    return redirect_to(:action=>"login") if session[:user]
    if request.post? && params[:user] && is_human=simple_captcha_valid?
      @user=Admin::SystemUser.find_by_email(params[:user][:email])
      if @user
        @user.reset_password
        RequestMailer.deliver_forgot_password(@user.email,:user=>@user, :host=>request.host)
        flash.now[:send_notice]=I18n.t("lolita.admin.user.forgot_password.send_notice")
      else
        flash.now[:forgot_password_error]= I18n.t(:"flash.user not found")
      end
    else
      if request.post? && !is_human
        flash.now[:forgot_password_error]= I18n.t(:"flash.human controll not correct")
      end
    end
    render :layout=>"admin/public"
  end

  # Called when change password link, delivered to email, is clicked.
  def change_password
    @user=Admin::SystemUser.change_password_for(params[:id])
    if @user && request.post? && params[:user]
      @user.renew_password(params[:user][:password])
      flash.now[:change_password_notice]=I18n.t("lolita.admin.user.change_password.notice")
    elsif !@user
      flash.now[:change_password_error]=I18n.t("lolita.admin.user.change_password.error")
    end
    render :layout=>"admin/public"
  end

  # Render index partial when AJAX request is received or call <i>list</i> action
  # otherwise.
  def current_roles # :nodoc:
    if request.xhr?
      render :partial=>'index',
        :locals=>{:user_obj=>Admin::User.find_unknown_user(:first,{:id=>params[:id]})},
        :layout=>false
    else
      list
    end
  end

  # Render users for <i>roles</i> view. Render partial form or redirects to
  # <i>roles</i> list view. On wrong requests redirects to login screen or return
  # nothing on Ajax requests.
  def index
    if @role = Admin::Role.find_by_id(params[:role_id])
      if request.xhr?
        render :partial=>'admin/role/tabs', :locals=>{:role=>@role,:active_tab=>:users,:active_role=>@role}
      else
        redirect_to list_role_url(@role.id,:tab=>:users)
      end
    else
      request.xhr? ? render(:nothing=>true) : redirect_to(login_users)
    end
  end

  private

  def before_destroy # :nodoc:
    if Admin::SystemUser.find_by_id(params[:id])==session[:user]
      @my_params.delete(:id)
    end
  end
  
  def set_active_user # :nodoc:
    @active_user=Admin::User.find_by_id(params[:id])
  end

  def config
    {
      :object=>"Admin::SystemUser",
      :tabs=>[
        {:type=>:content,:in_form=>true,:opened=>true,:fields=>:default},
        {:type=>:multimedia,:media=>:image_file,:single=>true}
      ],
      :list=>{
        :conditions=>["type=?","Admin::SystemUser"],
        :options=>[:edit,:destroy],
        :per_page=>100
      },
      :fields=>[
        {:type=>:text,:field=>:login,:html=>{:maxlength=>255}},
        {:type=>:text,:field=>:email,:html=>{:maxlength=>255}},
        {:type=>:password,:field=>:password,:html=>{:maxlength=>40}}
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
