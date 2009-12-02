module Extensions::LinkHelper
  include Extensions::SystemHelper
  # Iespējamā konfigurācija
  #   :controller - kontrolieris uz kādu ir links, ja nav tad paņem to pašu ko parametros
  #   :action - linka actions
  #   :paging - vai lapot, iedarbība jūtama list
  #   :clear - netiek pievienoti automātiskie parametri linkam, tiek pievienoti padotie
  #   :on_complete - javascript, ko izpilda pie veiksmīgas izpildes
  #   :on_failure - javascript, ko izpildīt neveiksmīgā pieprasījuma gadījumā
  #   :id - linka id
  #   :html - visas opcijas, ko izmantot veidojot linku
  #   :params - parametri ko pievienot linkam
  #   :image - String, tad ievietos title vietā attēlu ar šo adresi, vai Boolean, tad
  #            tiks ievietots attēls <code>edit</code> un <code>delete</code> actionam
  #   :title - Teksts kas parādās linka vietā, ja ir :image tad tas neparādās
  #   :container - Dom elements kuru atjaunot ar atbildes tekstu, ir jēga, ja nav :complete
  #
  def default_link config={}
    return "" unless config
    action=(config[:action] || params[:action]).to_sym
    can= Admin::User.current_user.is_admin? || Admin::User.current_user.can_access_action?(
      action,
      config[:controller] || params[:controller],
      @permissions
    ) 
    config[:params]||={}
    config[:params]=add_params_for_actions(config[:params]) if [:edit,:new,:destroy].include?(action)
    
    config[:params]=config[:params].delete_if{|key,value| !value }
    config[:params][:paging]||=config[:paging]
    config[:container]||="content"
    unless config[:clear]
      config[:params].merge!(copy_params(config[:params]))
    end
    if can && config[:image]
      if config[:image].is_a? String
        title="#{config[:image]}&nbsp;"
      else
        case config[:action].to_sym
        when :destroy
          title="#{image_tag("/lolita/images/icons/trash.gif")}&nbsp;"
        when :edit
          title="#{image_tag("/lolita/images/icons/edit.png")}&nbsp;"
        end
      end
    else
      title=config[:title]
    end
    config[:method]=config[:method] || "GET"
    if can || params[:action].to_sym==:edit
      cms_link title,config
    else
      ""  #params[:action].to_sym!=:create && params[:action]!=:delete ? title :
    end
  end

  def add_params_for_actions(params)
    params[:page]=@page && @page.respond_to?(:current_page) ? @page.current_page : nil
    params
  end
  
  def copy_params(base={})
    result={}
    params.each{|key,value|
      result[key]=value if key.to_s.match(/\w+_id$/) && value && !base.has_key?(key)
    }
    result
  end
  # Return anchor, onclick action call simple_yui_request with given configuration.
  # Arguments
  #   <tt>title</tt> - Specifies the html in anchor element
  # All posible options:
  #   <tt>:controller</tt> - Controller name
  #   <tt>:action</tt> - Action name
  #   <tt>:id</tt> - Record id
  #   <tt>:params</tt> - Additional parameters added to link url (hash) {:name=>"Ted"}
  #   <tt>:method/tt> - Request method, default POST
  #   <tt>:confirm</tt> - Confirmation question and only after positiv answer request starts
  #   <tt>:container</tt> - DOM element id witch content is updated on success,
  #   <tt>:loading</tt> - Show or not loading dialog,
  #   if not specified and <tt>:on_success</tt> or <tt>:on_complete</tt> callbacks, then nothig is done after loading
  # Callbacks are called only if confirmation answer is yes on not confirmation set 
  #   <tt>:before</tt> - Before request
  #   <tt>:after</tt> - After request started, but before loading completed
  #   <tt>:on_complete</tt> - When request completed
  #   <tt>:on_success</tt> - When request succesfuly completed, overrides <tt>:on_complete</tt>
  #   <tt>:on_failure</tt> - When request unsuccesfuly completed, overrides <tt>:on_complete</tt>
  def cms_link (title,options={},onclick=nil)
    base_params=options[:url] || {:controller=>options[:controller] || params[:controller],:action=>options[:action] || params[:action],:id=>options[:id]}
    options[:params][:authenticity_token]=form_authenticity_token if !options[:params][:authenticity_token]
    request_configuration={
      :url=>url_for(base_params),
      :data=>url_for((options[:params]||{}).merge(:only_path=>true,:escape=>false)).split("?")[1],
      :success=>options[:on_success] || options[:on_complete],
      :failure=>options[:on_failure] || options[:on_complete],
      :before=>options[:before],
      :after=>options[:after],
      :confirm=>options[:confirm],
      :container=>options[:container],
      :method=>options[:method] || "GET",
      :loading=>options.has_key?(:loading) ? options[:loading] : true
    }.delete_if{|key,value| value.nil?}.to_json.gsub(/"/,"&quot;")
    on_click=onclick || %!onclick="SimpleRequest(this,#{request_configuration});return false;"!
    result=%(<a #{cms_html_options(options[:html] || {})} #{on_click} href="#{base_params.is_a?(Hash) ? url_for(base_params.merge(options[:params] || {})) : base_params}" >#{title}</a>)
    result.html_safe!
  end

  #var norādīt back_link :previous, kas ir tips, kas atgriežas uz iepriekšējo adresi, ja tāda ir
  
  def back_link config={}
    config[:type]||=:default
    config[:paging]=nil
    config[:title]||=t(:"actions.back")
    config[:action]||="list"
    back_url=session[:start_links].pop if session[:start_links].is_a?(Array)
    config[:type]==:previous && back_url ?
      cms_link(config[:title],config.merge!(back_url)).html_safe! :
      default_link(config).html_safe!
  end
  def destroy_link config={}
    config[:title]||=t(:"actions.destroy")
    config[:action]="destroy"
    config[:method]="POST"
    config[:params]=(config[:params]||{}).merge(:_method=>"delete")
    config[:confirm]=t(:"actions.destroy confirmation")
    default_link(config).html_safe!
  end
  
  def update_link config={}
    config[:title]||=t(:"actions.confirm")
    config[:action]="update"
    config[:method]="POST"
    default_link(config).html_safe!
  end
  def edit_link config={}
    config[:title]||=t(:"actions.edit")
    config[:action]="edit"
    config[:method]="GET"
    default_link(config).html_safe!
  end
  
  def show_link config={}
    config[:title]||=t(:"actions.show")
    config[:action]="show"
    default_link(config).html_safe!
  end
  def list_link config={}
    config[:paging]=config.has_key?(:paging) ? config[:paging] : true
    config[:title]||=t(:"actions.list")
    config[:action]="list"
    config[:method]="POST"
    default_link(config).html_safe!
  end
  def new_link config={}
    config[:title]||=t(:"actions.new")
    config[:action]="new"
    default_link(config).html_safe!
  end
  def create_link config={}
    config[:title]||=t(:"actions.confirm")
    config[:action]="create"
    config[:method]="POST"
    default_link(config).html_safe!
  end
  # Obligātie parametri
  #   <tt>target_id</tt> - elementa id, kurā tiks ievietots teksts un kurš tiek parādīts un noslēpts
  # Iespējams norādīt
  #   <tt>:opened</tt> - vai mērķa elements ir redzams (atvērts)
  #   <tt>:title</tt> - virsraksts kurš tiks pievienots aiz bultas
  #
  def toggable_link target_id,options={}
    options[:loading]=false
    options[:container]||=target_id
    options[:method]="GET"
    options[:url]=url_for(:controller=>options[:controller] || params[:controller],:action=>options[:action] || params[:action],:id=>options[:id]) unless options[:simple]
    options=options.delete_if{|key,value| [:controller,:action,:id].include?(key)}
    # if options[:title]
    #    image_tag("/lolita/images/#{options[:opened] ? "cms/arrow_blue_s.gif" : "cms/arrow_blue_e.gif"}",:alt=>"",:id=>"#{target_id}_switch")+options[:title].to_s+
    #    options[:title]=image_tag("/lolita/images/#{options[:opened] ? "cms/arrow_blue_s.gif" : "cms/arrow_blue_e.gif"}",:alt=>"",:id=>"#{target_id}_switch")+options[:title].to_s
    #    options[:on_complete]=%($("#{target_id}").update(request.responseText))
    #    options[:before]=%(if(is_toggle_element_opened("#{target_id}")){add_very_small_loading("#{target_id}")}else{stop=true})
    #    link=cms_link(options[:title],options)
    #  else
    #.to_json.gsub(/"/,"&quot;")
    #  end
    status={:small_loading=>true,:state=>options[:opened],:images=>["arrow_blue_s.gif","arrow_blue_e.gif"]}
    (image_tag("/lolita/images/#{options[:opened] ? "cms/arrow_blue_s.gif" : "cms/arrow_blue_e.gif"}",:alt=>"",:class=>"toggle-arrow",:id=>"#{target_id}_switch")+options[:title].to_s+
      javascript_tag(%^ new ITH.ToggableElement("#{target_id}_switch","#{target_id}",#{status.to_json},#{options.to_json})^)).html_safe!

    end
  end
