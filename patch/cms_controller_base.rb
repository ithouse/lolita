class ::Class
  #  if env['HTTP_USER_AGENT'] =~ /^(Adobe|Shockwave) Flash/
  #    params = ::Rack::Utils.parse_query(env['QUERY_STRING'])
  #    env['HTTP_COOKIE'] = [ @session_key, params[@session_key] ].join('=').freeze unless params[@session_key].nil?
  #  end
  #  @app.call(env)
  attr_reader :roles
  attr_reader :permissions
  @@default_actions=[
    [:"actions.list","list"],
    [:"actions.new","new"]
  ] #TODO šim varbūt šeit nav īstā vieta, bet kur ir?

  #allow function is made for access control to controller
  #you add allow after controller defination, mostly in second line
  #it works with hash,string or array arguments
  #supports options as
  #only - list of allowed methods to access by users except system_admin
  #except - list of methods that not allowed, you can you either only or except
  #         depends of methods count in controller you want to allow access
  #public - list of methods that can access anyone, something like guest mode
  #
  def allow *args
    if Lolita.config.system :multi_domain_portal
      before_filter do |controller|
        controller.sso
      end
    end
    attr_accessor :roles
    attr_accessor :permissions
    attr_accessor :public_actions
    attr_accessor :system_actions
    @roles,@permissions=get_roles_and_options args
    #self.roles=@roles
    #self.permissions=@permissions
    before_filter do |controller|
      controller.roles=@roles
      controller.permissions=@permissions
      controller.public_actions=self.public_actions
      controller.system_actions=self.system_actions
      controller.allow
    end
  end

  def menu_actions actions={}
    if actions[:public].is_a?(Hash)
      @public_actions=actions[:public].to_a.collect!{|row|[row.last,row.first]}
    else
      @public_actions=actions[:public]
    end
    if actions[:system].is_a?(Hash)
      @system_actions=actions[:system].to_a.collect!{|row|[row.last,row.first]}
    else
      @system_actions=actions[:system]
    end
  end

  def default_actions
    @@default_actions
  end

  def system_actions
    @system_actions || []
  end

  def public_actions
    @public_actions || []
  end

  def access_control options={}
    attr_accessor :included_actions
    attr_accessor :excluded_actions
    attr_accessor :redirect_forbidden_actions_to
 
    if options.is_a?(Hash)
      in_act=options[:included] || []
      ex_act=options[:excluded] || []
      redirect=options[:redirect_to]
      before_filter do |controller|
        controller.included_actions=in_act
        controller.excluded_actions=ex_act
        controller.redirect_forbidden_actions_to=redirect
        controller.access_control
      end
    else
      return false
    end
  end
  private
  #with access_controll you can manage accessability of controller methods
  #this is simple way to allow or denay
 
  # Kontrolierī var norādīt vienu lomu vai vairākas un pārējos parametrus
  # Vienu lomu norādot to var rakstīt kā:
  #   allow "editor"
  # norādot vairākas lomas
  #   allow :roles=>["editor","blogger"]
  #
  def get_roles_and_options args
    args=args[0].is_a?(Array) ? args[0] : args
    if args[0].is_a?(String)
      r=args[0]
      p=args[1]
    elsif args[0] && !args[0].empty?
      r=args[0][:roles]
      p=args[0].delete_if{|key,value| key==:roles}
    end
    return r,p||{}
  end
end
#module ActionController
#  class Dispatcher
#    before_dispatch :clone_session_for_flash
#    def clone_session_for_flash
#      #r=@request
#      #RAILS_DEFAULT_LOGGER.warn("UserAgent:"+r.env['HTTP_USER_AGENT'].to_s)
#      #RAILS_DEFAULT_LOGGER.warn("Query:"+r.env['QUERY_STRING'].to_s)
#      #RAILS_DEFAULT_LOGGER.warn("Path:"+r.env['PATH_INFO'].to_s)
#      if r.env['HTTP_USER_AGENT']=~ /^(Adobe|Shockwave) Flash/ && match=r.env['QUERY_STRING'].to_s.match(/sid=(\w{32})/)
#        if FLASH_ACTIONS.include?(r.env['PATH_INFO']) || FLASH_ACTIONS.include?(r.env['SCRIPT_NAME'])
#          sid=match[1]
#          r.env['HTTP_COOKIE']="" unless r.env['HTTP_COOKIE']
#          unless r.env['HTTP_COOKIE']=~/#{SESSION_NAME}=#{sid}/
#            if r.env['HTTP_COOKIE']=~/#{SESSION_NAME}=\w{32}/
#              r.env['HTTP_COOKIE'].gsub!(/#{SESSION_NAME}=\w{32}/,[ SESSION_NAME,sid ].join('=')).freeze #unless params[@session_key].nil?
#            else
#              r.env['HTTP_COOKIE']<<((r.env['HTTP_COOKIE'].to_s.size>0 ? ";" : "")+[SESSION_NAME,sid].join("="))
#              r.env['HTTP_COOKIE'].freeze
#            end
#            if r.cgi.cookies[SESSION_NAME] && !r.cgi.cookies[SESSION_NAME].is_a?(Array)
#              r.cgi.cookies[SESSION_NAME].value[0]=sid
#            else
#              newcookie=CGI::Cookie::new(SESSION_NAME,sid)
#              r.cgi.cookies[SESSION_NAME]=newcookie
#            end
#          end
#        else
#          RAILS_DEFAULT_LOGGER.warn("Wrong URL for Flash Upload")
#          #RAILS_DEFAULT_LOGGER.warn("#{r.cgi.env_table.to_yaml}")
#        end
#      end
#    end
#  end
#end