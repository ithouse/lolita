# This controller is meant to be used as a _superclass_ for project spefific user controllers.
# ==login_public_user
# Method authenticate user by receiving +klass+, +login+ and +password+ and if
# authentication is successful then yield user, so any specific rules for user can
# be defined.
# * <tt>klass</tt> - User class where user belongs
# Also +options+ can be speficied.
#
# * <tt>:success</tt> - When login success
#   * <tt>:partial</tt> - If specified return that partial with appropriate status code.
#   * <tt>:template</tt> - Template
#   * <tt>:layout</tt> - Layout for template.
#   * <tt>:locals</tt> - Is used as locals when rendering :partial or :template.
#   * OR
#   * <tt>:url</tt> - The URL to redirect on successful login unless :partial is specified.
#
# * <tt>:error</tt> - When login failed
#   * <tt>:partial</tt> - If specified return that partial with appropriate status code.
#   * <tt>:template</tt> - Template
#   * <tt>:layout</tt> - Layout for template.
#   * <tt>:locals</tt> - Is used as locals when rendering :partial or :template.
#   * OR
#   * <tt>:url</tt> - The URL to redirect on successful login unless :partial is specified.
#
# * OR
#
# * <tt>:partial</tt> - If specified return that partial with appropriate status code.
# * <tt>:template</tt> - Template
# * <tt>:layout</tt> - Layout for template.
# * <tt>:locals</tt> - Is used as locals when rendering :partial or :template.
# * OR
# * <tt>:url</tt> - The URL to redirect on successful login unless :partial is specified.
#
# * <tt>:flash_auth_failed</tt> - Message that is set in <tt>flash[:error]</tt> if failed to login.
# * <tt>:no_flash</tt> - If is set to _true_ than no message is written in <tt>flash[:error]</tt>
# * <tt>:allowed_classes</tt> - Define Array of User classes that can authenticate through this class or Sysmbols, :all
# * <tt>:method</tt> - options are (:login,:email,:any), this will determinate which method of authenticate will be used
# ====Example
#   login_public_user BlogUser, 'user', 'password', :success => {:url=>blogs_start_page_url} do |user|
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

# ==To create custom public user controller and model follow these steps
#1. solis - Izveidojam kontrolieri ar kaut kādu nosaukumu, piemēram, SimpleUser (turpmāk arī šo izmantosim), pēc tam arī modeli un helperi ar šādu pat nosaukumu
#2. solis - Sataisam modeli, lai darbotos
#     a) SimpleUser < Admin::PublicUser
#     b) set_table_name :admin_users
#3. solis - Sataisam kontrolieri
#    a) SimpleUserController < Admin::PublicUserController
#    b) Sataisam funkcijas, kas nepieciešamas tieši šim kontrolierim (4.solis), un ja vajag pieliekam konfigurāciju (5.solis)
#4.solis - Funkcijas (action)
#   a) Lietotāja publiskā izveidošana (registration), liekam iekšā jebko kas vajadzīgs, nav nepieciešama nekāda saistība ar Lolitu
#   b) Pieteikšanās - ieliekam visu, ko vajag pirms vai pēc pieteikšanās, kaut kādu datu pārbaudi vai tamlīdzīgi, pēc ieliekam render kādu vajag, var arī nekas nebūt ne pirms ne pēc. Svarīgākais liekam Admin::PublicUserController privāto funkciju login_public_user un padodam bloku (Skatīt dokumentāciju sīkākai informācijai)
#c) Izlogošanās - izmantojam logout_public_user (skatīt dokumentāciju)
#5. solis - Izmantošana administratīvajā pusē
#   a) Izveidojam konfigurāciju, privātā config funkcija, skatīt Managed#config
#   b) Izveidot _list.html.erb skatu, izskatas var būt jebkāds, bet principā, _list var apskatīties jebkurā vietā, kur tāds ir, kaut vai lolitas viewos
#   c) Noklusējuma HTML _list view
#<%#
## SIA Lolita
## Artūrs Meisters
#%>
#<script type="text/javascript">
#  loadjscssfile("/lolita/javascripts/cms/administration.js?<%=rand(1000)%>","js")
#</script>
#<table summary="user list">
#  <tr>
#    <%= list_header_cell :width=>450, :sort_column=>"login",:title=>SimpleUser.human_attribute_name("login") %>
#    <%= list_header_cell :width=>70, :title=>t(:"list.options")%>
#  </tr>
#  <% for user in @page %>
#    <tr>
#      <td>
#       <%= render :partial=>"/admin/user/roles_list_link", :locals=>{:record=>user,:active_user=>@active_user} %>
#      </td>
#      <td>
#        <% list_options(user){|option| %>
#          <%= option %>&nbsp;
#        <% } %>
#      </td>
#    </tr>
#  <% end %>
#</table>
#<%= cms_pages list%>
class Admin::PublicUserController < Managed

  private
  
  def login_public_user klass,login,password,options={}
    if request.post? && params[:user]
      user = klass.authenticate(params[:user][login],params[:user][password],options[:allowed_classes],options[:method])
      loged_in=if block_given?
        yield user if user
      else
        true
      end
      if user && loged_in
        register_user_in_session user
        remember_me user
        redirect_login options[:success] || options
      else
        flash.now[:error]||=options[:flash_auth_failed] || I18n.t(:"flash.error.auth failed") unless options[:no_flash]
        redirect_login options[:error] || options
      end
    else
      redirect_login options if logged_in?
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

  def redirect_login options = {}
    unless (options[:partial] || options[:text] || options[:json])
      redirect_back_or_default options[:url] || home_url
    else
      render_login options
    end
  end

  def render_login options
    render_options = {}
    render_options[:layout]   = options[:layout] if options[:layout]
    render_options[:template] = options[:template] if options[:template]
    render_options[:partial]  = options[:partial] if options[:partial]
    render_options[:text]     = options[:text] if options[:text]
    render_options[:json]     = options[:json] if options[:json]
    render_options[:locals]   = options[:locals] if options[:locals]
    render_options[:status]   = logged_in? ? 200 : 401
    render render_options
  end

  def remember_me(user)
    user.remember_me if !user.remember_token? && params[:user][:remember_user].to_i==1
    cookies[:auth_token] = { :value => user.remember_token , :expires => user.remember_token_expires_at }
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
