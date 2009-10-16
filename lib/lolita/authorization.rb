module Lolita
  module Authorization
    def self.included(base)
      base.class_eval{
        include InstanceMethods
      }
      if base == ActionController::Base
        base.extend(ControllerClassMethods)
        base.class_eval{
          include(ControllerInstanceMethods)
        }
      end
    end

    module InstanceMethods
      protected
      
      def public_user?
        !current_user.is_a? Admin::SystemUser if logged_in?
      end

      def system_user?
        !public_user? if logged_in?
      end

      # Returns true or false if the user is logged in.
      # Preloads @current_user with the user model if they're logged in.
      def logged_in?
        !current_user.nil?
      end

      #-------------------#
      # Izmaiņas
      # - ar current_user pieglabājam gan usera id gan klasi, jo ir iespējami dažādi useri
      #
      # FIXME: login_required izmanto Admin::User, vai tā ir ok?
      #-------------------#

      # Accesses the current user from the session.
      def current_user
        return @current_user if @current_user
        @current_user = (session[:user] && session[:user][:user_class].find_by_id(session[:user][:user_id])) || nil
        @current_user
      end

      def current_user=(user)
        @current_user=user
      end
    end

    module ControllerClassMethods
      attr_reader :roles, :permissions
      @@default_actions=[
        [:"actions.list","list"],
        [:"actions.new","new"]
      ]
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
        if args[0] && args[0].is_a?(Hash)
          r=args[0][:roles]
          p=args[0].delete_if{|key,value| key==:roles}
        else
          r=args[0].to_s
          p=args[1]
        end
        return r,p||{}
      end
    end

    module ControllerInstanceMethods
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
          login_from_cookie unless logged_in?
          allowed=Admin::User.authenticate_in_controller({
              :action=>params[:action].to_sym,
              :controller=>params[:controller],
              :user=>current_user,
              :permissions=>self.permissions,
              :roles=>self.roles
            })
          session[:return_to]=params if Admin::User.area==:public && request.get? && !params[:format]
          after_allow if allowed && self.respond_to?("after_allow",true)
        end

        if !allowed
          if system_user?
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
        render :template=>"errors/error_500", :layout=>false
      end

      def access_control
        included=is_action_in?(params[:action],self.included_actions)
        excluded=is_action_in?(params[:action],self.excluded_actions)
        if (included && !excluded) || (!excluded && self.included_actions.empty?)
          (block_given?)? yield: return
        else
          unless self.redirect_forbidden_actions_to
            if system_user?
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

      protected

      # Store the given user in the session.
      def set_current_user(new_user)
        session[:user] = (new_user.nil? || new_user.is_a?(Symbol)) ? nil : {:user_id => new_user.id, :user_class => new_user.class}
        @current_user = new_user
      end

      def reset_current_user
        session[:user]=nil
        @current_user=nil
      end
      # Check if the user is authorized.
      #
      # Override this method in your controllers if you want to restrict access
      # to only a few actions or if you want to check if the user
      # has the correct rights.
      #
      # Example:
      #
      #  # only allow nonbobs
      #  def authorize?
      #    current_user.login != "bob"
      #  end
      def authorized?
        true
      end

      # Filter method to enforce a login requirement.
      #
      # To require logins for all actions, use this in your controllers:
      #
      #   before_filter :login_required
      #
      # To require logins for specific actions, use this in your controllers:
      #
      #   before_filter :login_required, :only => [ :edit, :update ]
      #
      # To skip this in a subclassed controller:
      #
      #   skip_before_filter :login_required
      #
      def login_required
        username, passwd = get_auth_data
        self.current_user ||= Admin::User.authenticate(username, passwd) || :false if username && passwd
        logged_in? && authorized? ? true : access_denied
      end

      # Redirect as appropriate when an access request fails.
      #
      # The default action is to redirect to the login screen.
      #
      # Override this method in your controllers if you want to have special
      # behavior in case the user is not authorized
      # to access the requested action.  For example, a popup window might
      # simply close itself.
      def access_denied
        respond_to do |accepts|
          accepts.html do
            store_location
            redirect_to :controller => '/admin/user', :action => 'login'
          end
          accepts.xml do
            headers["Status"]           = "Unauthorized"
            headers["WWW-Authenticate"] = %(Basic realm="Web Password")
            render :text => "Could't authenticate you", :status => '401 Unauthorized'
          end
        end
        false
      end

      # Store the URI of the current request in the session.
      #
      # We can return to this location by calling #redirect_back_or_default.
      def store_location
        session[:return_to] = request.request_uri
      end

      # Redirect to the URI stored by the most recent store_location call or
      # to the passed default.
      def redirect_back_or_default(default)
        session[:return_to] ? redirect_to(session[:return_to]) : redirect_to(default)
        session[:return_to] = nil
      end

      # When called with before_filter :login_from_cookie will check for an :auth_token
      # cookie and log the user back in if apropriate
      def login_from_cookie
        return unless cookies[:auth_token] && !logged_in?
        user = Admin::User.find_by_remember_token(cookies[:auth_token])
        if user && user.remember_token?
          user.remember_me
          self.current_user = user
          cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
          flash[:notice] = "Veiksmīga pieteikšanās"
        end
      end

      private
      @@http_auth_headers = %w(X-HTTP_AUTHORIZATION HTTP_AUTHORIZATION Authorization)
      # gets BASIC auth info
      def get_auth_data
        auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
        auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
        return auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil]
      end

      def is_action_in? action,object
        if object.is_a?(Array)
          object.include?(action.to_sym)
        elsif object.is_a?(Hash)
          object.keys.include?(action.to_sym)
        end
      end
    end
  end
end
