require 'extensions/file_manager'
require 'extensions/advanced_filter_extension'
require 'extensions/paging'
require 'extensions/permission_controll'
require 'extensions/util'

class ActionController::Base
#  Admin::Token
#
#  Admin::SystemUser
#  Admin::PublicUser
  #helper :all
  include AuthenticatedSystem
  include Extensions::FileManager
  include Extensions::PermissionControll
  include Extensions::Paging
  include Extensions::Translation
  include Extensions::Util
  #include Extensions::AdvancedFilterExtension
  #include Extensions::Sso
  
  #if Lolita.config.translation
  before_filter :set_locale
  #end

  def render_404(status=404)
    respond_to do |type|
      type.html { render :template => "errors/error_404", :status => status }
      type.all  { render :nothing => true, :status => status }
    end
  end

  def render_500(status=500)
    respond_to do |type|
      type.html { render :template => "errors/error_500", :status => status }
      type.all  { render :nothing => true, :status => status }
    end
  end

  protected

  def get_main_portal
    @main_portal||=Admin::Portal.find_by_root(true)
    @main_portal
  end

  def not_main_portal?()
    domain=request.domain(Lolita.config.domain_depth)
    domain==get_main_portal.domain ? nil : Admin::Portal.find_by_domain(domain)
  end
  
  def load_cache
    if allow_caching
      path=request.path
      file_name=if (path=="" || path=="/")
        unless domain=not_main_portal?
          "/index"
        else
          "/index_#{domain.id}"
        end
      else
        URI.unescape(path.chomp('/'))
      end
      file_name<<(!path.match(/\.\w+$/) ? ".html" : "")
      base_directory=ActionController::Base.page_cache_directory
      base_directory=base_directory.slice(0,base_directory.size-1)
      file_path=base_directory.+file_name
      if File.exist?(file_path)
        RAILS_DEFAULT_LOGGER.info("Ielādēju kešu: #{file_path}")
        text=File.read(file_path)
        render :text=>text
        return false
      end
    end
  end

  def allow_caching
    ActionController::Base.perform_caching && request.get?
  end

  def layout_name(category=nil)
    if category && design=category.design
      "cms/#{design.name}"
    elsif portal=not_main_portal?
        "cms/#{portal.design}"
    else
      "cms/#{Cms::Design.find_by_root(true).name}"
    end
  end
  

  def is_local_request?
    request.host=="localhost"
  end

  def namespace
    params[:controller].to_s.split("/").first
  end
  def only_controller
    params[:controller].to_s.split("/").last
  end

  def send_bug msg, title=''
    msg = "
    <h3>Pieprasījums</h3>
    <dl>
      <dt>IP</dt> <dd>#{request.remote_ip}</dd>
      <dt>URL</dt> <dd>#{request.url}</dd>
      <dt>Metode</dt> <dd>#{request.request_method}</dd>
      <dt>Pārlūks</dt> <dd>#{request.env['HTTP_USER_AGENT']}</dd>
      <dt>Izcelsme</dt> <dd>#{request.env["HTTP_REFERER"] || "-Bez izcelsmes-"}</dd>
      <dt>Ajax</dt> <dd>#{request.xml_http_request?}</dd>
      <dt>Parametri</dt> <dd>#{join_hash(params)}</dd>
    </dl>
    <h3>#{title}</h3>
    <pre>
    #{msg}
    </pre>"
    RequestMailer::deliver_mail(
      "bugs@ithouse.lv",
      "#{request.host_with_port} automātiskais kļūdas paziņojums (#{500})",
      {:header=>msg},"bugs@telegraf.lv"
    )
  end
  
  def join_hash h
    "<ul>#{h.collect{|k,v| "<li>#{k} => #{v.instance_of?(HashWithIndifferentAccess)? join_hash(v) : v}</li>"}}</ul>"
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
    #FIXME: wtf?
    false #request.remote_addr == LOCALHOST and request.remote_ip == LOCALHOST
  end
 
end