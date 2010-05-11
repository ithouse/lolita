module Extensions::PagingHelper
  # Create paginator for public side of page.
  # Method can be called with block or without for single page link.
  # #Lolita::Paginator need to pass as +page+. Also +options+ can be provided and current +page_number+
  # When +page_number+ is given then return link only for that page, block can be provided as well.
  # Allowed options:
  # * <tt>:controller</tt> - Controller name for link, default current controller
  # * <tt>:action</tt> - Action name for link, default current action
  # * <tt>:params</tt> - Additional params for URL
  # * <tt>:html</tt> - HTML options that are added to anchor element
  # * <tt>:first_page</tt> - First page number to show in paginator, default +page+ first page.
  # * <tt>:last_page</tt> - Last page number to render, default +page+ last page.
  # * <tt>:container</tt> - If specified than AJAX function on click will be called
  # * <tt>:ajax</tt> - If set to true, then return options otherwise link, is useful when create specific anchor element.
  # * <tt>:page_name</tt> - Name of the page, default is page number, but can be string mixed with page number or without it.
  # ====Example
  #     @page=Post.lolita_paginate({:per_page=>10,:page=>2,:padding=>2})
  #     public_page(@page,:container=>"posts_container", :action=>"index") do |page_nuber,url,options|
  #      <%= link_to page_number, url, options %>
  #     end
  #     #=> create AJAX paginator from 1 to 4, because padding is 2 and current page is 2.
  #     public_page(@page,{:container=>"post_container",:page_name=>"<span class='page'>Page %d</span>"},1)
  #     #=> create AJAX paginator for page 1, and return link with name <i>Page 1</i>.
  #
  def public_page page,options={},page_number=nil
    if page.total_pages>1
      url={
        :controller=>options[:controller] || params[:controller],
        :action=>options[:action]|| params[:action],
        :page=>page_number
      }
      options[:html]||={}
      options[:params]||={}
      class_name=""
      unless page_number
        (options[:first_page] || page.first_page).upto(options[:last_page] || page.last_page) do |page_nr|
          options[:params][:page]=page_nr
          if page_nr==page.current_page
            class_name=options[:html][:class] ? options[:html][:class].dup : nil
            options[:html][:class]="#{options[:html][:class]} current"
          else
            options[:html][:class]=class_name
          end
          yield public_page_link(page_nr,url,options).html_safe!
        end
      else
        if block_given?
          yield public_page_link(page_number,url,options).html_safe!
        else
          public_page_link(page_number,url,options).html_safe!
        end
      end
    end
  end

  # Create link for paginator or return given options with new values added to them.
  # Wait for +page_number+ and +url+ for link and other options can be passed as well. For details see #public_page.
  # If paginator need to be created then user #public_page not this method.
  def public_page_link(page_number,url,options={})
    name=options[:page_name] ? options[:page_name].to_s % page_number : page_number
    options[:html]||={}
    options[:html][:onclick]="ajax_paginator('#{url_for(url.merge(:only_path=>true))}','#{options[:container]}',#{options[:params].to_json});return false;" if options[:container]
    unless options[:ajax]
      link_to(name, url_for(url.merge(options[:params] || {})),options[:html])
    else
      options
    end
  end
  
  # Toggle sort direction from <code>params[:sort_direction]</code>, default is _desc_.
  def sort_direction
    if params[:sort_direction]
      params[:sort_direction]=="desc" ? "asc" : "desc"
    else
      "desc"
    end
  end
  # Izveido lapošanas konteineri ar lapām un nepieciešamajiem parametriem<br/>
  # Iespējams norādīt vairākas opcijas
  # <tt>controller</tt> - norāda kontrolieri uz kuru vedīs saite, ja nav tad tekošais<br/>
  # <tt>action</tt> - action, kas tiks izsaukts<br/>
  # <tt>container</tt> - <i>html</i> elementa id, kas tiks pārlādēts ar saņemto atbildes tekstu<br/>
  # <tt>params</tt> - parametri, kas tiks pievienoti pieprasījumam<br/>
  # <tt>position</tt> - novietojums, kas tiek pievienots klases nosaukumam <i>page-number-container-:position</i><br/>
  # Pēc noklusējuma tiek pievienoti :paging,:sort_column un :sort_direction
  #
  #     cms_pages :controller=>"/cms/news", :action=>:list, :container=>"my_container",
  #               :params=>{:name=>"example"}, :position=>"top"
  #     #=> "/cms/news/list?name=example"
  #     cms_pages :action=>:advanced_list
  #     #=> "/cms/news/advanced_action"
  # Create paginator for Lolita administrative side. Is useful only in Lolita backend.
  def cms_pages options={}
    #current_class=(@config[:parent_name] || params[:controller].camelize.constantize.name.underscore).to_sym
    options[:params]||={}
    options[:params][:paging]=true
    options[:page]||=@page
    options[:params].merge!({:sort_column=>options[:page].simple_sort_column,:sort_direction=>options[:page].sort_direction})
    page_container="<div class='page-number-container-#{options[:position] || "bottom"}'>"
    page_numbers(options[:page],{
        :controller=>options[:controller] || params[:controller],
        :action=>options[:action] || params[:action],
        :container=>options[:container] || 'form_list',
        :params=>options[:params]
      }) do |page|
      page_container<<page
    end
    "#{page_container}</div>".html_safe!
  end
  
  def page_numbers page,options={}
    url_params={
      :controller=>options.has_key?(:controller) ? options[:controller] : params[:controller],
      :action=>options.has_key?(:action) ? options[:action] : params[:action] ,
      :params=>options[:params]||{}
    }
    temp_params=params.dup
    #temp_params.merge!(url_params[:params])
    [:controller,:action].each{|key| temp_params.delete(key)}
    url_params[:params]=temp_params.merge(url_params[:params])
    
    container=options[:container] || 'form_list'
    if options[:simple_link]
      link_method=:simple_link
    else
      link_method=:page_link
    end

    if options[:simple_link] 
      next_page=page.next_page
      previous_page=page.previous_page
    else
      next_page=page.page_count
      previous_page=1
    end
    
    first_page=options[:first_page] ? options[:first_page] : page.first_page
    last_page=options[:last_page] ? options[:last_page] : page.last_page
    if page.page_count>1
      if page.current_page!=1
        yield self.send(link_method,previous_page, url_params, :first=>true,:current=>page.current_page,:container=>container,:ajax=>options[:ajax])
      end
      first_page.upto(last_page) do |page_number|
        yield self.send(link_method,page_number, url_params,:current=>page.current_page,:container=>container,:ajax=>options[:ajax])
      end
      if page.current_page!=page.page_count
        yield self.send(link_method,next_page, url_params,:last=>true, :current=>page.current_page,:container=>container,:ajax=>options[:ajax])
      end
    end
  end
  
  def page_link page, url, options={}
    url[:params][:page]=page
    cfg={:method=>"POST",:title=>page_number(page,options),:container=>options[:container]}.merge(url)
    default_link cfg
  end

  def simple_link page,url,options={}
    url[:params]||={}
    url[:params][:page]=page
    if options[:first]
      title=t(:"public.prev_page")
      html={:class=>"prev"}
    elsif options[:last]
      title=t(:"public.next_page")
      html={:class=>"next"}
    else
      html={}
      title=page
    end
    html[:onclick]="ajax_paginator('#{url_for(url[:params])}','#{options[:container]}');return false;" if options[:ajax]
    link_to title,url[:params],html
  end
  
  def page_number page,options={}
    content=options[:first] ? "&lt;&lt;" : (options[:last] ? "&gt;&gt;" : (page<10 ? "0#{page}" : page))
    "<span class='#{!options[:first] && !options[:last] && page==options[:current] ? "current_" : ""}page_number'>#{content}</span>"
  end
end