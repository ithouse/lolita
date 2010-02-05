# coding:utf-8
module Lolita
  module ControllerKernel
    def self.included(base) # :nodoc: 
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      # Render <i>404</i> error with given *status* and *layout*.
      # Try to find error template in /public directory, it can be
      # 404.<i>:locale</i>.html or 404.html.
      # If none of templates found in /public, then render from /errors/error_404 in *lolita*.
      def render_404(status=404,layout="default")
        respond_to do |type|
          type.all  { render :nothing => true, :status => status }
          unless params.empty?
            type.html do
              ["public/404.#{I18n.locale}.html", "public/404.html"].each do |f_path|
                if File.exists?(File.join(RAILS_ROOT,f_path))
                  return render(:file => f_path, :status => status)
                end
              end
              render :template => "errors/error_404", :status => status, :layout=>layout
            end
          else
            render :nothing => true, :status => status
          end
        end
      end

      # Render 500 error template with given *status* code.
      # See #render_404 for details.
      def render_500(status=500)
        options = {:template => "errors/error_500", :status => status }
        begin
          options[:layout] = false if request.path == home_path
        rescue # if home_path doesn't exist
        end
        respond_to do |type|
          type.all  { render :nothing => true, :status => status }
          type.html do
            ["public/500.#{I18n.locale}.html","public/500.html"].each do |f_path|
              if File.exists?(File.join(RAILS_ROOT,f_path))
                return render(:file => f_path, :status => status)
              end
            end
            render options
          end
        end
      end

      protected

      def is_local_request?
        request.host=="localhost"
      end

      def namespace
        params[:controller].to_s.split("/").first
      end

      def only_controller
        params[:controller].to_s.split("/").last
      end

      # Send error e-mail to email -> :bugs_to, from email -> :bugs_from.
      # By default _request_ information are added to email body, separately
      # error <i>message</i> and <i>title</i> can be specified.
      def send_bug msg=nil, title=nil
        RequestMailer.deliver_bug(:msg => msg, :title => title, :request => request, :params => params, :session => session)
      end

      def rescue_action_in_public(exception)
        case exception
        when ActiveRecord::RecordNotFound, ActionController::RoutingError, ActionController::UnknownController, ActionController::UnknownAction
          render_404
        else
          send_bug("#{exception.to_s}\n\n#{$@.join("\n")}", "Error")
          render_500
        end
      end

      def local_request? #:doc:
        false #request.remote_addr == LOCALHOST and request.remote_ip == LOCALHOST
      end
    end
  end
end
