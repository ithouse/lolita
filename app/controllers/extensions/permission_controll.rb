module Extensions::PermissionControll
  
  # Nosaka vai lietotājam ir pieeja norādītajam kontolierim
  #
  # Example:
  #          <tt>allow '/cms/news'  -> true or yield, ja current_user ir pieeja news</tt>
  # def allowed controller
  #   controller=model_from_controller controller
  #  if is_admin? || has_permission?(false,controller)
  #    block_given? ? yield : return
  #  else
  #     false
  #   end
  #  end
  # Nodrošina piekļuvi kontrolierim vai metodei vai atseviškai koda daļai.
  # Var izsaukt kā funkciju vai ar bloku, gadījumā ja piekļuve liegt tad pāradresē
  # uz pieteikšanās logu.
  #
  # Parametri:
  #   :public=>   Array ar publiski pieejamām metodēm
  #   :except=> Array ar metodēm, kurām neatļaut piekļuvi izņēmums - "system_admin"
  #   :only=>     Array ar metodēm, TIKAI kurām ir atļauta piekļuve izņēmums - "system_admin"
  #   :roles=>     Array ar lomām, kurām ir piekļuve modulim
  #   :actions=> Hash ar metodēm(atslēgas) un pieejas šai metodei (sk. Admin::User.can_do_special_action_in_controller?)
  # Example:
  #   Pieeja kontrolierim
  #          <tt>allow "system_admin" -> pieeja tikai system_admin visam kontrolierim</tt>
  #          <tt>allow "system_admin",:public=>[:login] -> 
  #                 pieeja tikai system_admin visam kontrolierim, izņēmums view funkcija
  #                 pieejama vieiem
  #          </tt>
  #          <tt>allow :only=>[:show] -> pieeja visām lomām ar piekļuvi šim kontrolierim funkcijai 'show'</tt>
  #          <tt>allow do 
  #               put "Atļauts"
  #              end
  #            -> "Atļauts" redzams tikai, ja lomai piekļuve kontrolierim un lietotājam ir tāda loma
  #          </tt>
  def allow
    unless params[:action].to_sym==:allow
      flash[:notice]=nil if flash[:notice]==t(:"flash.access.denied") || flash[:notice]==t(:"flash.need to login")
      authenticate_from_cookies unless session[:p_user]
      allowed=Admin::User.authenticate_in_controller(
        params[:action].to_sym,
        params[:controller],
        {:system=>current_user,:public=>session[:p_user]},
        self.permissions,self.roles
      )
      session[:return_to]=params if Admin::User.area==:public && request.get? && !params[:format]
      after_allow if allowed && self.respond_to?("after_allow",true)
    end
    
    if !allowed
      if session[:user] && session[:user].is_a?(Admin::SystemUser)
        to_user_login_screen
      else
        to_login_screen
      end unless allowed
    elsif allowed && block_given?
      yield
    elsif allowed
      return true
    elsif !block_given?
      return false
    end
  end
  
  def to_login_screen
    return unless self.respond_to?( :redirect_to )
    flash[:notice] = t(:"flash.need to login")
    session[:return_to]=request.request_uri unless params[:format]
    redirect_to home_url
    return false
  end

  def to_user_login_screen
    return unless self.respond_to?( :redirect_to )
    flash[:notice] = t(:"flash.access denied")
    session[:return_to]=request.request_uri unless params[:format]
    render :template=>"status/access_denay", :layout=>params[:is_ajax].to_b ? false : "cms/default"
  end

  def access_control
    #    if args && args[0].is_a?(Array) && !args[1]
    #      argumenti=args[0][0]
    #    else
    #      argumenti=args
    #    end
    #    accessable_methods=[]
    #    excluded_methods=[]
    #    case argumenti.class.to_s
    #    when "Array"
    #      accessable_methods=argumenti
    #    when "String" || "Symbol"
    #      accessable_methods<<argumenti.to_sym
    #    when "Hash"
    #      accessable_methods=argumenti[:included] || []
    #      excluded_methods=argumenti[:excluded] || []
    #      redirect=argumenti[:redirect_to]
    #    end
    #    action=params[:action].to_sym
    #    inc=accessable_methods.include?(action)
    #    exc=excluded_methods.include?(action)
    included=is_action_in?(params[:action],self.included_actions)
    excluded=is_action_in?(params[:action],self.excluded_actions)
    if (included && !excluded) || (!excluded && self.included_actions.empty?)
      (block_given?)? yield: return
    else
      unless self.redirect_forbidden_actions_to
        if session[:user] && session[:user].is_a?(Admin::SystemUser)
          to_user_login_screen
        else
          to_login_screen
        end
      else
        redirect[:is_ajax]=params[:is_ajax]
        redirect_to(self.redirect_forbidden_actions_to)
      end
    end
  end

  private

  def authenticate_from_cookies
    if cookies[:remember_me]
      u=Admin::User.find_by_remember_token(cookies[:remember_me])
      if u && Admin::User.access_to_area?({:p_user=>u}) #access pārbauda, lai būtu drošs ka var
        session[:p_user]=u
      else
        cookies.delete(:remember_me)
      end
    end
  end

  def is_action_in? action,object
    if object.is_a?(Array)
      object.include?(action.to_sym)
    elsif object.is_a?(Hash)
      object.keys.include?(action.to_sym)
    end
  end
end
