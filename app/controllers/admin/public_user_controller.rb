class Admin::PublicUserController < ApplicationController

  private

  def login_public_user klass,login,password,options={}
    flash[:error]=nil
    if request.post? && params[:user]
      user = klass.authenticate(params[:user][login],params[:user][password])
      loged_in=yield user if user
      if user && loged_in
        register_user_in_session user
        redirect_to options[:login_url] || home_url
      else
        flash[:error]=I18n.t(:"flash.login failed")
      end
    else
      redirect_to options[:login_url] || home_url if logged_in?
    end
  end
  
  def remember_me(user)
    cookies.delete :remember_me unless user.remember_token
    domain=request.domain()
    if params[:remember_me] && !user.remember_token
      user.update_attributes!(:remember_token=>Digest::SHA1.hexdigest("$$#{Time.now.to_s}$$#{params[:login]}$$"))
      cookies[:remember_me]={:value=>user.remember_token,:expires=>7.days.from_now,:domain=>domain}
    elsif user.remember_token
      cookies[:remember_me]={:value=>user.remember_token,:expires=>7.days.from_now,:domain=>domain}
    end
  end
  
  def reset_remember_me
    current_user.update_attributes!(:remember_token=>nil) if public_user? && current_user.remember_token
    cookies.delete(:remember_me)
  end

  def reset_sso #lai varētu šeit ielik vēl ko ja vajadzēs
    Admin::Token.destroy_all(["user_id=? OR updated_at<?",current_user.id,1.day.ago]) if Lolita.config.system :multi_domain_portal && !is_local_request?
    cookies.delete(:sso_token)
  end
  
  def send_registration_email user,header,text
  #FIXME
  end
  
  def register_user_in_session user
    session.data.delete(:user)
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
