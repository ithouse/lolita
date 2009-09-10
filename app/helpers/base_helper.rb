# Methods added to this helper will be available to all templates in the application.
module BaseHelper
  include Extensions::PermissionHelper
  include Extensions::NumberSpellerHelper

  include Extensions::ErrorHelper
  include Extensions::JavaScriptHelper
  include Extensions::SystemHelper
  include Extensions::PagingHelper
  include Extensions::FieldHelper
  include Extensions::MenuHelper
  include Extensions::HumanControlHelper
  include Extensions::ReportsHelper
  include Extensions::FilterHelper
  include Extensions::LinkHelper
  include Extensions::FormHelper
  include Extensions::UrlHelper
  include PublicHelper
  include ManagedHelper
  include Media::BaseHelper
  # Iespējamās opcijas
  #   :image - vai nepieciešams tekstā pielikt klāt ITHouse
  #   :simple - vienkārša lapa vai nē
  def creator_link(options={})
    locale=cookies[:locale] || session[:locale]
    locale=Lolita.config.language_code if !locale && Lolita.config.language_code
    if locale=="en"
      text="Web development"
      title="Web development / Website development"
      link="http://www.ithouse.cc"
    elsif locale=="ru"
      text=options[:simple] ? "Cоздание сайтов" : "Web разработка"
      title="Cоздание сайтов / Web разработка"
      link="http://www.ithouse.lv"
    else
      text=options[:simple] ? "Mājas lapu izstrāde" : "Web izstrāde"
      title="Mājas lapu izstrāde / Web izstrāde"
      link="http://www.ithouse.lv"
    end
    title+=" | IT House"
    text=options[:text] if options[:text]
    %(<a href="#{link}" title="#{title}" target="_blank" style="text-decoration:none;">#{text}#{options[:image] ? "" : ": IT House"}</a>)
  end
  
  def domain_link_to title,url,domain=false, options={}
    if domain
      link_to title,"http://#{domain}#{url}",options
    else
      link_to title,url,options
    end
  end
  def get_main_portal
    @main_portal||=Admin::Portal.find_by_root(true)
    @main_portal
  end

  def not_main_portal?()
    domain=request.domain(Lolita.config.domain_depth)
    domain==get_main_portal.domain ? nil : Admin::Portal.find_by_domain(domain)
  end
  
  def current_session_name
    params[:controller].gsub(/^\//,"").gsub("/","_").to_sym
  end
  
  def user
    session[:user].nil? || session[:user]==:false ? nil : session[:user]
  end
  
  def only_controller
    params[:controller].split("/").last if params[:controller]
  end
  
  def namespace
    params[:controller].split("/").first if params[:controller]
  end

  def calculate_percents data={}
    result=[]
    data[:all].each_with_index{|value,index|
      if data[:total].to_i>0
        r=((value.to_f/data[:total].to_f)*100)
        result<<[index,r,r.ceil.to_f-r]
      else
        result<<[0,0,0]
      end
    }
    if result.inject(0){|sum,r| r[1]}<100
      sorted_result=result.sort_by{|r| r[2]}
      greater=sorted_result.last
    end
    result.collect!{|r|
      if greater && greater[0]==r[0]
        r[1].ceil
      else
        r[1].floor
      end
    }
    result
  end

  def cms_flv_player flash_vars={},html_options={},flash_options={}
    html_options[:id]||= "flash_player_#{rand(10000)}"
    flash_options[:wmode]="transparent"
    flash_options[:allowfullscreen]=true unless flash_options.has_key?(:allowfullscreen)
    flash_options[:allowscriptaccess]="always" unless flash_options.has_key?(:allowscriptaccess)
    vars=flash_vars.collect{|key,value|
      "#{key}=#{value}"
    }.join("&")
    msg = t(:"flash.get flash player")
    base_options={:player=>"/lolita/public_swf/player.swf",:type=>"player",:width=>html_options[:width] || 480,:height=>html_options[:height] || 350,:version=>html_options[:version] || '9'}
    %(<div id="#{html_options[:id]}"><div class="no-flash-msg">#{msg}</div><noscript>#{image_tag(flash_vars[:image],:alt=>"")}</noscript></div>)+
      javascript_tag(
      %(FlashLoader.create('#{html_options[:id]}',#{base_options.to_json},'#{vars}',#{flash_options.to_json}))
    )
  end
  def month_names options={}
    months=[
      t(:"months.january"),t(:"months.february"),
      t(:"months.march"),t(:"months.april"),
      t(:"months.may"),t(:"months.june"),
      t(:"months.july"),t(:"months.august"),
      t(:"months.september"),t(:"months.october"),
      t(:"months.november"),t(:"months.december"),
    ]
    months.collect!{|month| month.capitalize} if options[:capitalize]
    months
  end
  def cms_text_value_html_from_element element
    if !element.is_a?(String) && element.respond_to?("last")
      [element.first,element[1],element.last]
    else
      [element,element]
    end
  end
  
  def cms_html_options html
    if Hash===html
      options=""
      html.each{|key,value|
        options<<%(#{key}="#{html_escape(value.to_s)}" ) if value
      }
      options
    end
  end
  def cms_options_for_select container,selected=nil,escaped=true
    container = container.to_a if Hash === container
    options_for_select = container.inject([]) do |options, element|
      text, value,html = cms_text_value_html_from_element element
      if (selected.is_a?(Array) && selected.include?(value)) || selected==value
        selected_attribute = ' selected="selected"'
      end
      html_options=cms_html_options html
      options << %(<option #{html_options} value="#{html_escape(value.to_s)}"#{selected_attribute}>#{escaped ? html_escape(text.to_s) : text.to_s}</option>)
    end
    options_for_select.join("")
  end
  
  def meta_description
    md=MetaData.by_metaable get_id,params[:controller]
    md=Admin::Menu.best_menu_item_for_params(params) unless md
    md.description if md
  end

  def meta_keywords
    md=MetaData.by_metaable get_id,params[:controller]
    md=Admin::Menu.best_menu_item_for_params(params) unless md
    md.tags if md
  end
  
  def meta_title
    md=MetaData.by_metaable get_id,params[:controller]
    md=Admin::Menu.best_menu_item_for_params(params) unless md
    md.title if md
  end
  def odd_class_name state
    state ? "odd" : ""
  end
  
  def markers
    begin
      params[:controller].camelize.constantize.marker_set.markers.each{|marker|
        yield %(<span style="color:#{marker.color}">#{marker.color_name}</span>: #{marker.title})
      }
    rescue
    end
  end
  
  
  def file_cfg container,options={}
    configuration=container[:configuration] || {}
    excluded=options[:excluded] || []
    cfg={:configuration=>configuration}
    container.each{|key,value|
      cfg[key]=value unless cfg[key] || excluded.include?(key)
    }
    options.each{|key,value|
      cfg[key]=value unless excluded.include?(key)
    }
    cfg
  end
  
  def picture_cfg_form_fields container,options={}
    result=""
    excluded=options[:excluded]||[]
    container.each{|key,value|
      unless excluded.include?(key) || value.is_a?(Hash) || value.is_a?(Array)
        result+=%(<input type="hidden" name="#{key}" value="#{value}" />)
      end
    }
    if container[:configuration]
      container[:configuration].each{|key,value|
        result+=%(<input type="hidden" name="#{key}" value="#{value}" />) unless excluded.include?(key)
      }
    end
    options.each{|key,value|
      result+=%(<input type="hidden" name="#{key}" value="#{value}" />)
    }
    result
  end
  
  def month_name nr, loc="kas?"
    m=[{"Janvār"=>1},{"Februār"=>1},{"Mart"=>0},{"Aprīl"=>1},{"Maij"=>0},
      {"Jūnij"=>0},{"Jūlij"=>0},{"August"=>0},{"Septembr"=>1},{"Oktobr"=>1},
      {"Novembr"=>1},{"Decembr"=>1}
    ]
    dekl=[
      {"kas?"=>"s","kā?"=>"a","kam?"=>"am","ko?"=>"u","kur?"=>"ā"},
      {"kas?"=>"is","kā?"=>"a","kam?"=>"im","ko?"=>"i","kur?"=>"ī"}
    ]
    "#{m[nr-1].keys.first}#{dekl[m[nr-1].values.first][loc]}"
  end
  
  def is_active_sort_column?(sort_column)
    if params[:sort_columns]==sort_column
      "active"
    end
  end
  def sort_data(sort_column,options={})
    hsh={:controller=>params[:controller],:action=>'show',:sort_direction=>params[:sort_direction]=='asc' && params[:sort_columns]==sort_column ? 'desc' : 'asc',:sort_columns=>nil}
    params.each{|key,value|
      if key.to_s!='sort_columns' && key.to_s!='sort_direction'
        hsh[key]=value unless hsh[key]||hsh[key.to_s]
      end
    }
    hsh.merge!(options)
    hsh[:sort_columns]=sort_column
    hsh
  end
 
  def page_title
    parts=params[:controller].split(/\//)
    controller=parts.size>1?parts[1]:parts[0]
    actions={:list=>'saraksts',:update=>'labošana',:create=>'veidošana',:show=>'rādīšana'}
    if table=Admin::Table.find_by_name(controller)
      title=table.human_name.to_s.size>0 ? table.human_name : controller
    else
      title=controller
    end
    title=title.humanize
    title+=" (#{actions[params[:action].to_sym] || params[:action]})"
    title
  end
  def list_start_tags
    '<div class="m"><div class="b"> <div class="t"> <div class="l"><div class="r">
     <div class="br"> <div class="bl"> <div class="tr"><div class="tl">'
  end
  def list_end_tags
    "</div></div></div></div></div></div></div></div></div>"
  end
  def javascript_response
    content_tag('div',
      content_tag('div',
        content_tag('div',"",:class=>'r',:id=>"javascript_response_content"),
        :class=>'l'),
      :class=>'greenbox',:id=>"javascript_response",:style=>"display:none;"
    )
  end
  def flash_response
    if flash[:notice]
      result=content_tag('div',
        content_tag('div',
          content_tag('div',flash[:notice],:class=>'r', :id=>"flash_response"),
          :class=>'l'),
        :class=>'greenbox')
    else
      result=error_messages_for_cms flash[:error]
    end
    #flash(true)
    result
  end
  
  def user_link
    link_to current_user.email,{:action=>'edit_self',:controller=>'/admin/user',:id=>current_user.id},{:class=>"grey", :style=>params[:action]=="edit_self" ? "text-decoration:underline" : ""} if current_user
  end
 
  def checkbox value,id
    chck=(value)?"checked='checked'":""
    id=(id)?("id=#{id}"):""
    "<input #{id} type='checkbox' '#{chck}' />"
  end

  def cut_words(text="",len=0)
    words=text.split(" ")
    text=words.slice(0..len)
    text.join(" ")+(words.size>len ? "..." : "")
  end
  
  def cut_text(text="",len=0)
    words=text.split(" ")
    clen=0
    result=""
    index=0
    while clen<len and words[index]
      clen+=words[index].size
      result+=words[index]+" " if(clen<=len)
      index+=1
    end
    result+="..." if text.size>len
    result
  end

  def cut_html(html="",len=0)
    search=true
    result=html.gsub(/(<p[^>]*>).+<\/p>/){|match|
      body=strip_tags(match) if search
      if strip_tags(result).to_s.size+body.to_s.size<=len
        result+=match
      elsif strip_tags(result).to_s.size<len
        words=body.split(" ")
        match.gsub(/(<p[^>]*>)/){|inner_match|
          result<<inner_match
        }
        words.each{|word|
          if result.to_s.size.to_i+word.to_i<len
            result<<"#{words.first==word ? "" : " "}#{word}"
          else
            break
          end
        }
        result<<"...</p>"
        break
      else
        search=false
      end
    }
    result
  end
  
  def escape_html(str)
    str.to_s.gsub(/[&\"><]/,"")
  end
  

  
  # HELPERS FOR HTML SNIPLET GENERATION IN PUBLIC LAYOUT
  #  <li><a href="#" class="active">LV</a></li>
  #          <li><a href="#">RU</a></li>
  #          <li><a href="#">ENG</a></li>
  def language_menu
    base = Admin::Language.find_base_language
    langs = Admin::Language.find_additional_languages
    current=Globalize::Locale.language_code.upcase
    langs.unshift(base)
    langs.each {|lang|
      url= { :locale=>lang.short_name}
      params.each{|key,value|
        unless key.to_sym==:locale
          url[key]=value
        end
      }
      yield link_to(lang.short_name.upcase,url,{:class=>current==lang.short_name.upcase ? "active" : ""})
    }
  end
end

