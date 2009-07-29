class ::ActionController::Base
#  Admin::Token
#
#  Admin::SystemUser
#  Admin::PublicUser
  #helper :all
 
  #
  #include Extensions::Sso

  def default_url_options options = {}
    logger.debug "default_url_options is passed options: #{options.inspect}\n" unless options.empty?
    { :locale => I18n.locale }
  end
  
  protected

  def get_main_portal
    @main_portal||=Admin::Portal.find_by_root(true)
    @main_portal
  end

  def not_main_portal?()
    domain=request.domain(LOLITA_DOMAIN_DEPTH)
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
        RAILS_DEFAULT_LOGGER.debug("Ielādēju kešu: #{file_path}")
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
  
  def filter_ip_address
    unless Admin::IpFilter.is_trusted?(request.remote_ip)
      render :template=>"status/401"
      return false
    else
      return true
    end
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
    unless request.host=="localhost"
      send_bug("#{exception.to_s}\n\n#{$@.join("\n")}", "Kļūda")
      render :template => "status/error", :status => 500
    end
  end

  def local_request? #:doc:
    false #request.remote_addr == LOCALHOST and request.remote_ip == LOCALHOST
  end
 
end