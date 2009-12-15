module ControllerExtensions::Sso
  def sso
    return true if controller_name == "sso" || params[:format]=="xml" || is_local_request? || request.env['HTTP_USER_AGENT']=~ /^(Adobe|Shockwave) Flash/ || robot?
    set_current_portal
    if public_user? && cookies[:sso_token] && !Admin::Token.find_by_token(cookies[:sso_token])
      reset_session
      cookies.delete(:sso_token)
    end
    Admin::Token.current_token = Admin::Token.find_by_token(cookies[:sso_token]) if cookies[:sso_token]
    if (!session[:sso_verified] || !Admin::Token.current_token)
      Admin::Token.current_token = Admin::Token.create!(
        :token => new_sso_hash,
        :uri => request.request_uri,
        :portal => Admin::Portal.current_portal
      )
      redirect_to "http://#{Admin::Portal.find_by_root(true).domain}#{request.port!=80 ? ":#{request.port}" : ""}" <<
        "/sso/verify/#{Admin::Token.current_token.token}" and return false
    end
  end

  private

  def robot?
    bot = /(Baidu|bot|Google|SiteUptime|Slurp|WordPress|Yandex|ZIBB|ZyBorg)/i
    request.env['HTTP_USER_AGENT'] =~ bot
  end

  def new_sso_hash
    result=""
    80.times { result << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
    result
  end

  def set_sso_cookie
    if Admin::Token.current_token
      cookies[:sso_token]=Admin::Token.current_token.token
      session[:sso_token]=Admin::Token.current_token.token
      set_current_user Admin::Token.current_token.user
    end
    if current_user && current_user.remember_token
      cookies[:remember_me]=current_user.remember_token
    end
  end

  def set_current_portal
    if !Admin::Portal.current_portal || (Admin::Portal.current_portal && Admin::Portal.current_portal.domain!=request.domain(Lolita.config.system :domain_depth))
      Admin::Portal.current_portal=Admin::Portal.find_by_domain(request.domain(Lolita.config.system :domain_depth))
    elsif !Admin::Portal.current_portal
      Admin::Portal.current_portal=Admin::Portal.find_by_root(true)
    end
  end
end
