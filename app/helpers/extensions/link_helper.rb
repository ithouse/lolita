# All links in Lolita views should be generated via helper method provided by this module.
module Extensions::LinkHelper
  include Extensions::SystemHelper
  # Create Lolita style link. Also check if user can open that kind of link and no display
  # those that not allowed. Add necessary parameters to link and display image or text depending
  # on options passed.
  # Accepted configuration:
  # * <tt>:controller</tt> - Controller name.
  # * <tt>:action</tt> - Action name.
  # * <tt>:paging</tt> - Paging or not, that is necessary for list action.
  # * <tt>:clear</tt> - Only passed params are added to link.
  # * <tt>:on_complete</tt> - JavaScript to evalute when request ends successfuly.
  # * <tt>:on_failure</tt> - JavaScript to evalute when request fail.
  # * <tt>:id</tt> - ID used when link need ID, useful for shorter syntax.
  # * <tt>:html</tt> - HTML options for anchor element.
  # * <tt>:params</tt> - Params that will be added to link.
  # * <tt>:image</tt> - Image path or :edit or :delete for default images.
  # * <tt>:title</tt> - Title used as link text.
  # * <tt>:container</tt> - DOM element ID that content will be replaced with response text.
  # For details see #cms_link
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

  # Add page number to params that is added to link, used by #default_link.
  def add_params_for_actions(params)
    params[:page]=@page && @page.respond_to?(:current_page) ? @page.current_page : nil
    params
  end

  # Copy all params that ends with _id to link unless same param is already given.
  def copy_params(base={})
    result={}
    params.each{|key,value|
      result[key]=value if key.to_s.match(/\w+_id$/) && value && !base.has_key?(key)
    }
    result
  end
  # Return anchor, onclick action call simple_yui_request with given configuration.
  # Arguments
  # * <tt>title</tt> - Specifies the html in anchor element
  # All posible options:
  # * <tt>:controller</tt> - Controller name
  # * <tt>:action</tt> - Action name
  # * <tt>:id</tt> - Record id
  # * <tt>:params</tt> - Additional parameters added to link url (hash) {:name=>"Ted"}
  # * <tt>:method/tt> - Request method, default POST
  # * <tt>:confirm</tt> - Confirmation question and only after positiv answer request starts
  # * <tt>:container</tt> - DOM element id witch content is updated on success,
  # * <tt>:loading</tt> - Show or not loading dialog,
  #   if not specified and <tt>:on_success</tt> or <tt>:on_complete</tt> callbacks, then nothig is done after loading
  # Callbacks are called only if confirmation answer is yes on not confirmation set 
  # * <tt>:before</tt> - Before request
  # * <tt>:after</tt> - After request started, but before loading completed
  # * <tt>:on_complete</tt> - When request completed
  # * <tt>:on_success</tt> - When request succesfuly completed, overrides <tt>:on_complete</tt>
  # * <tt>:on_failure</tt> - When request unsuccesfuly completed, overrides <tt>:on_complete</tt>
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

  # Create back link, that point to action that was called before current action.
  # Defaults:
  # * <tt>:paging</tt> - nil
  # * <tt>:title</tt> - actions.back from translations
  # * <tt>:action</tt> - list
  # Accepted options:
  # * <tt>:type</tt> - :previous or :default (by default), when :previous is set, then uses link
  #                    from session (Deprecated).
  # For options details see #default_link.
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
  # Create destroy link, for +config+ details see #default_link and #cms_link.
  # Defaults
  # * <tt>:title</tt> - actions.destroy
  # * <tt>:confirm</tt> - actions.destroy confirmation
  def destroy_link config={}
    config[:title]||=t(:"actions.destroy")
    config[:action]="destroy"
    config[:method]="POST"
    config[:params]=(config[:params]||{}).merge(:_method=>"delete")
    config[:confirm]||=t(:"actions.destroy confirmation")
    default_link(config).html_safe!
  end

  # Create update link, for +config+ details see #default_link and #cms_link.
  # Defaults
  # * <tt>:title</tt> - actions.confirm
  def update_link config={}
    config[:title]||=t(:"actions.confirm")
    config[:action]="update"
    config[:method]="POST"
    default_link(config).html_safe!
  end

  # Create edit link, for +config+ details see #default_link and #cms_link.
  # Defaults
  # * <tt>:title</tt> - actions.edit
  def edit_link config={}
    config[:title]||=t(:"actions.edit")
    config[:action]="edit"
    config[:method]="GET"
    default_link(config).html_safe!
  end

  # Create show link. See #default_link and #cms_link
  # Defaults
  # * <tt>:title</tt> - actions.show
  def show_link config={}
    config[:title]||=t(:"actions.show")
    config[:action]="show"
    default_link(config).html_safe!
  end

  # Create list link. See #default_link and #cms_link
  # Defaults
  # * <tt>:title</tt> - actions.list
  def list_link config={}
    config[:paging]=config.has_key?(:paging) ? config[:paging] : true
    config[:title]||=t(:"actions.list")
    config[:action]="list"
    config[:method]="POST"
    default_link(config).html_safe!
  end

  # Create new action link. See #default_link and #cms_link.
  # Defaults
  # * <tt>:title</tt> - actions.new
  def new_link config={}
    config[:title]||=t(:"actions.new")
    config[:action]="new"
    default_link(config).html_safe!
  end

  # Create <i>create</i> action link. See #default_link and #cms_link.
  # Defaults
  # * <tt>:title</tt> - actions.confirm
  def create_link config={}
    config[:title]||=t(:"actions.confirm")
    config[:action]="create"
    config[:method]="POST"
    default_link(config).html_safe!
  end
  # Create toggable link, that is link with east/south arrow that open or close container with +target_id+.
  # Content of container can be loaded via Ajax or rendered before.
  # Allowed options:
  # * <tt>:container</tt> - Container id to open, by default +target_id+.
  # * <tt>:simple</tt> - Content will not be loaded.
  # * <tt>:controller, :action, :id</tt> - Used to get content of container.
  # * <tt>:opened</tt> - Is container opened at start or not.
  # * <tt>:title</tt> - Text that will be added after arrow.
  # Other options will be passed to JS, see ITH.ToggableElement
  #
  def toggable_link target_id,options={}
    options[:loading]=false
    options[:container]||=target_id
    options[:method]="GET"
    options[:url]=url_for(:controller=>options[:controller] || params[:controller],:action=>options[:action] || params[:action],:id=>options[:id]) unless options[:simple]
    options=options.delete_if{|key,value| [:controller,:action,:id].include?(key)}
    status={:small_loading=>true,:state=>options[:opened],:images=>["arrow_blue_s.gif","arrow_blue_e.gif"]}
    (image_tag("/lolita/images/#{options[:opened] ? "cms/arrow_blue_s.gif" : "cms/arrow_blue_e.gif"}",:alt=>"",:class=>"toggle-arrow",:id=>"#{target_id}_switch")+options[:title].to_s+
      javascript_tag(%^ new ITH.ToggableElement("#{target_id}_switch","#{target_id}",#{status.to_json},#{options.to_json})^)).html_safe!

    end
  end
