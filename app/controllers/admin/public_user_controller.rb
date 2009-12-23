# This controller is meant to be used as a _superclass_ for project spefific user controllers.
# ==login_public_user
# Method authenticate user by receiving +klass+, +login+ and +password+ and if
# authentication is successful then yield user, so any specific rules for user can
# be defined.
# * <tt>klass</tt> - User class where user belongs
# Also +options+ can be speficied.
# * <tt>:partial</tt> - If specified than always return that partial with appropriate status code.
# * <tt>:locals</tt> - Is used as locals when rendering :partial.
# * <tt>:url</tt> - The URL to redirect on successful login unless :partial is specified.
# * <tt>:flash_auth_failed</tt> - Message that is set in <tt>flash[:error]</tt> if failed to login.
# * <tt>:no_flash</tt> - If is set to _true_ than no message is written in <tt>flash[:error]</tt>
# ====Example
#   login_public_user BlogUser, 'user', 'password', :url=>blogs_start_page_url do |user|
#    user.is_accepted?
#   end
# ==logout_public_user
# Logout user from any part of system by deleting :user from session. An +options+ can be specified.
# * <tt>:url</tt> - The URL where to redirect after logout, default home_url
# * <tt>:no_flash</tt> - If set to _true_ than nothing is set in <tt>flash[:success]</tt>
# ====Example
#   logout_public_user :url=>"/", :no_flash=>true
# ==remember_me
# Remember user if params[:user][:remember_user] is specified, this method is called from <tt>login_public_user</tt>,
# but can be used seperate.
# ==render_partial
# Render if +options+ is spefified :partial value.
# * <tt>:partial</tt> - Render partial spefied as value.
# * <tt>:locals</tt> - Locals for render
class Admin::PublicUserController < ApplicationController

  private
  
  def login_public_user klass,login,password,options={}
    flash[:error]=nil
    if request.post? && params[:user]
      user = klass.authenticate(params[:user][login],params[:user][password])
      loged_in=yield user if user
      if user && loged_in
        register_user_in_session user
        remember_me user
        redirect_logged_in_user options
      else
        flash[:error]||=options[:flash_auth_failed] || I18n.t(:"flash.error.auth failed") unless options[:no_flash]
        render_partial options
      end
    else
      redirect_logged_in_user options if logged_in?
    end
  end

  def logout_public_user options={}
    if logged_in?
      self.current_user.forget_me
      reset_current_user
      flash[:success]||= I18n.t(:"flash.success.logout success") unless options[:no_flash]
    end
    redirect_to options[:url] || home_url
  end

  def redirect_logged_in_user options = {}
    unless options[:partial]
      redirect_to options[:url] || home_url
    else
      render_partial options
    end
  end

  def render_partial options
    if options[:partial]
      render_options = {
        :partial => options[:partial],
        :status => logged_in? ? 200 : 401
      }
      render_options[:locals] = options[:locals] if options[:locals]
      render render_options
    end
  end

  def remember_me(user)
    user.remember_me if !user.remember_token? && params[:user][:remember_user].to_i==1
    cookies[:auth_token] = { :value => user.remember_token , :expires => user.remember_token_expires_at }
  end

  def reset_sso #lai varētu šeit ielik vēl ko ja vajadzēs
    Admin::Token.destroy_all(["user_id=? OR updated_at<?",current_user.id,1.day.ago]) if Lolita.config.system :multi_domain_portal && !is_local_request?
    cookies.delete(:sso_token)
  end
  
  def send_registration_email user,header,text
    #FIXME
  end
  
  def register_user_in_session user
    session.to_hash.delete(:user)
    set_current_user user
  end

  def redirect_authenticated_user
    if request.xml_http_request?
      render :text=>"[true]"
    else
      redirect_back_or_default(home_url) and return
    end
  end

  def redirect_user
    if request.xml_http_request?
      redirect_to home_url
    else
      redirect_to home_url
    end
  end

  
end
