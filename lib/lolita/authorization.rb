# coding:utf-8
module Lolita
  # Add methods to check current user state and other ones that allow or restrict
  # access to different areas for different users.
  # Those methods are available in controllers and views as well.
  # There are #InstanceMethods that are common for views and controllers and
  # #ControllerInstanceMethods and #ControllerClassMethods that are only available
  # in controllers.
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

    # Common methods for controllers and views all methods are protected.
    module InstanceMethods
      protected

      # Returns true or false if the user is logged in.
      # Preloads @current_user with the user model if they're logged in.
      def logged_in?
        !current_user.nil?
      end

      # Return current user object.
      # Use this instead of direct use of _session_ user information.
      # _Session_ stores user class and user ID not user object itself.
      def current_user
        return @current_user if @current_user
        @current_user = (session[:user] && ( session[:user][:user_class].is_a?(String) ? session[:user][:user_class].constantize : session[:user][:user_class]).find_by_id(session[:user][:user_id])) || nil
        @current_user
      end

      # Setter method for +current_user+.
      # With this method you can set any other user as current user instead of
      # using _sesssion_ provided one.
      def current_user=(user)
        @current_user=user
      end
    end

    # Controller class method for authorization.
    # There are two main method for using in controllers #allow and #access_control.
    module ControllerClassMethods
      attr_reader :roles, :permissions
      @@default_actions=[
        [:"actions.list","list"],
        [:"actions.new","new"]
      ]
      # This method can be used in any controller and it gives before filter
      # that checks accessability of eacy request method and controller for
      # user that request for that method.

      # Special case is when only String is passed as first argument, so it will
      # be used instead of <i>:roles</i> array, as array with only one role.
      # Method accepts following configuration:
      # * <tt>:roles</tt> - Array of role names that can access controller.
      # * <tt>:public</tt> - Array of methods names that can be available for
      #                      all users and for those who not logged in at all.
      # * <tt>:public_system</tt> - Array of methods names that can be available
      #                      for all users but not for those who isn't logged in.
      # * <tt>:system</tt> - Array of methods names that can be available for all
      #                      system users and only for system users.
      # * <tt>:actions</tt> - Hash of methods as keys that can be accesses in
      #                       different way as usually when values are, not working when
      #                       <i>:roles</i> is passed:
      #   * <tt>Symbol</tt> - Type of permission, only users with that kind of
      #                       permission for controller can access that method.
      #                       Allowed permissions is:
      #     * <tt>:read</tt> - Only users who have reading access to controller.
      #     * <tt>:write</tt> - Users who have writing access to controller.
      #     * <tt>:update</tt> - Users who have updating access to controller.
      #     * <tt>:delete</tt> - Users who have deleting access to controller.
      #     * <tt>:any</tt> - Allow to access to users who have any type of access to controller.
      #     * <tt>:all</tt> - Users who have all accesses to controller.
      #   * <tt>String</tt> - Role name, only users with this role can access action.
      #   * <tt>Array</tt> - Array can contain Symbols of accesses or Strings with role
      #                      names, so if user match any of those than access to
      #                      that action will be granted.
      #   Administrator always can access all actions.
      # ====Example
      #     class Administration < ApplicationController
      #       allow Admin::Role.admin #=> only admin can access any action of this controller
      #     end
      #     ...
      #     allow :roles=>["editor","manager"] #=> only these roles can access action
      #     allow :public=>["index"], :system=>["destroy"]
      #       #=> anyone can access <i>index</i> action by only system users can access <i>destroy</i> action.
      #     allow "editor", :public=>[:post] #=> only editor can access all actions, but
      #                                          anyone can access <i>post</i> action.
      #     allow :public=>[:index], :actions=>{
      #       :update=>:update,
      #       :create=>:write,
      #       :change=>[:update,:write,"editor"]
      #       :destroy=>:all
      #     } #=> <i>index</i> is available for everyone, <i>update</i> is available only
      #     for those users who have :update access to this controller _create_ only for
      #     writing access, but change for those users who have :update, :write access or
      #     has role "editor", and finnaly _destroy_ action is available for users who have
      #     all permissions to this controller.
      def allow *args
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
          controller.set_locale
        end
      end

      def menu_actions actions={} # :nodoc:
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

      def default_actions # :nodoc:
        @@default_actions
      end

      def system_actions # :nodoc:
        @system_actions || []
      end

      def public_actions # :nodoc:
        @public_actions || []
      end

      # Use this method to forbid or allow access for specific actions.
      # Following arguments are accepted:
      # * <tt>:included</tt> - Deprecated don't use.
      # * <tt>:excluded</tt> - Array of actions names to forbid being seen.
      # * <tt>:redirect_forbidden_actions_to</tt> - Options for redirecting when
      #                        access to action is forbiden. See #redirect_to for details.
      # ====Example
      #     access_control :exclude=>[:index], :redirect_forbiden_actions_to=>{:action=>"list"}
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
      
      def allow # :nodoc:
        unless params[:action].to_sym==:allow
          flash[:notice]=nil if flash[:notice]==t(:"flash.access.denied") || flash[:notice]==t(:"flash.need to login")
          # login_from_cookie unless logged_in?
          allowed=Admin::User.authenticate_in_controller({
              :action=>params[:action].to_sym,
              :controller=>params[:controller],
              :user=>current_user,
              :permissions=>self.permissions,
              :roles=>self.roles
            })
          logger.error %(Authorization failed in #{params[:controller]}/#{params[:action]}
          for #{current_user ? current_user.login : "unknown user"} ) unless allowed
          after_allow if allowed && self.respond_to?("after_allow",true) # just for managed
        end
        store_location if Admin::User.area != :public && request.get? && !request.xhr?
        if !allowed
          if current_user.is_a?(Admin::SystemUser)
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

      # Redirect to <b>home_url</b> target depends on routes configuration.
      def to_login_screen
        return unless self.respond_to?( :redirect_to )
        flash[:notice] = t(:"flash.need to login")
        #session[:return_to]=request.request_uri unless params[:format]
        if request.xhr?
          render :text=>"Access denied!", :status => 401
        else
          redirect_to "/system/login"
        end
        return false
      end

      # Render error 500 template and show notice.
      def to_user_login_screen
        return unless self.respond_to?( :redirect_to )
        flash[:notice] = t(:"flash.access denied")
        #session[:return_to]=request.request_uri unless params[:format]
        render :template=>"errors/error_500", :layout=>false
      end

      def access_control # :nodoc:
        store_location
        included=is_action_in?(params[:action],self.included_actions)
        excluded=is_action_in?(params[:action],self.excluded_actions)
        if (included && !excluded) || (!excluded && self.included_actions.empty?)
          (block_given?)? yield: return
        else
          unless self.redirect_forbidden_actions_to
            if current_user.is_a?(Admin::SystemUser)
              to_user_login_screen
            else
              to_login_screen
            end
          else
            redirect[:is_ajax]=request.xhr?
            redirect_to(self.redirect_forbidden_actions_to)
          end
        end
      end

      protected

      # Store given user in session and set <b>current_user</b> variable.
      def set_current_user(new_user)
        if  new_user.kind_of?(ActiveRecord::Base)
          session[:user] = {:user_id => new_user.id, :user_class => new_user.class.to_s}
          @current_user = new_user
        else
          reset_current_user
        end
      end

      def reset_current_user
        session[:user]=nil
        session[:return_to]=nil
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
            render :text => "Could't authenticate you", :status => 401
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
       return_to = session[:return_to] || (params[:return_to] && params[:return_to] =~ /^\// ? params[:return_to] : nil)
       session[:return_to] = nil if session[:return_to]
       return_to ? redirect_to(return_to) : redirect_to(default)
      end

      # When called with before_filter :login_from_cookie will check for an :auth_token
      # cookie and log the user back in if apropriate
      def login_from_cookie(user_class)
        return unless cookies[:auth_token] && !logged_in?
        user = user_class.authenticate_by_cookies(cookies[:auth_token])
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
