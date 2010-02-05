# coding:utf-8
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
  include Extensions::ReportsHelper
  include Extensions::FilterHelper
  include Extensions::LinkHelper
  include PublicHelper
  include ManagedHelper
  include Media::BaseHelper
  # Iespējamās opcijas
  #   :image - vai nepieciešams tekstā pielikt klāt Lolita
  #   :simple - vienkārša lapa vai nē
  def creator_link(options={})
    locale=cookies[:locale] || session[:locale]
    locale=Lolita.config.i18n :language_code if !locale && Lolita.config.i18n(:language_code)
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
  #:nodoc:
  def domain_link_to title,url,domain=false, options={}
    if domain
      link_to title,"http://#{domain}#{url}",options
    else
      link_to title,url,options
    end
  end
  
  def current_session_name
    params[:controller].gsub(/^\//,"").gsub("/","_").to_sym
  end
  # Returns current user in session if exists else returns _nil_
  def user
    session[:user].nil? || session[:user]==:false ? nil : session[:user]
  end
  #Returns only controller name without the namespace.
  def only_controller
    params[:controller].split("/").last if params[:controller]
  end
  #Returns only namespace without controller if controller defined with namespace
  def namespace
    params[:controller].split("/").first if params[:controller]
  end
  # Calculates percoents for given values.
  # Accpet hash paramterer with options :total and :all described below.
  # Accepted options:
  # * <tt>:all</tt> - An array element with all the Fixnum values which needs to be calculated in percents.
  # * <tt>:total</tt> - Fixnum with the total sum of the elements values passed in <em>:all</em> array.
  # ====Result
  # Returns an array with each passed value represented in percents in the same order as they were passed in <em>:all</em> parameter
  # ====Example
  #   calculate_percents({:total=>100, :all=>[25,25,50]})
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
  # Creates flv player html from various options passed in to the helper
  # there are 3 parameter hashes accepted - flash_vars, html_options and flash_options all described in detail below.
  # Flv player uses default skin located in /lolita/public_swf/player.swf
  # Accepted options:
  # * <tt>flash_vars</tt> - The first parameter. All flash_vars are automaticaly formated and passed in to
  # the SWFObject as 'flashvars' parameter string.
  # ** <tt>:file</tt> - path to video file.
  # ** <tt>:image</tt> - optianaly path can be specified to image whcih will be show as the the first frame.
  # * <tt>html_options</tt> - The second parameter. All the options to modify the players html
  # ** <tt>:id</tt> - Id which will be set to container wraped around the flv player.
  # ** <tt>:width</tt> - Sets the flash player width, default:480px
  # ** <tt>:width</tt> - Sets the flash player height, default:350px
  # ** <tt>:version</tt> - Version of the macromedia flash player , default:9
  # * <tt>flash_options</tt> - The third parameter. Options for flv player modification.
  # All parameters supported by SWFObject can be passed in this option.
  # ** <tt>:allowfullscreen</tt> - true/false to enable or disable fullscreen mode  , default:true
  # ** <tt>:allowscriptaccess</tt> - Allow flash player to communicate with the pages html in which it is embanded, possible values are
  # 'always' - allow access to page html, 'sameDomain' - allow access only if video is on the same domain as page which it is displaying,
  # 'never' - do not allow acces to html  , default:'always'
  # ====Result
  # Returns an array with each passed value represented in percents in the same order as they were passed in <em>:all</em> parameter
  # ====Example
  #<%= cms_flv_player({:file => "video.flv",:image=>"poster.jpg"},{:width=>466,:height=>350,:id=>"test_video"},{:allowfullscreen=>'true'}) %>
  def cms_flv_player flash_vars={},html_options={},flash_options={}
    flash_vars[:skin]||="/lolita/swf/skin.swf"
    html_options[:id]||= "flash_player_#{rand(10000)}"
    flash_options[:wmode]="transparent"
    flash_options[:allowfullscreen]=true unless flash_options.has_key?(:allowfullscreen)
    flash_options[:allowscriptaccess]="always" unless flash_options.has_key?(:allowscriptaccess)
    vars=flash_vars.collect{|key,value|
      "#{key}=#{value}"
    }.join("&")
   # vars="{#{vars}}"
    par=flash_options.merge({:flashvars=>vars}).to_json
    msg = t(:"flash.get flash player")
    base_options={:player=>"/lolita/swf/player.swf",:type=>"player",:width=>html_options[:width] || 480,:height=>html_options[:height] || 350,:version=>html_options[:version] || '9'}
    %(<div id="#{html_options[:id]}"><div class="no-flash-msg">#{msg}</div><noscript>#{image_tag(flash_vars[:image],:alt=>"")}</noscript></div>)+
      javascript_tag(
      %(
      var fn = function() {
        var att = { data:"#{base_options[:player]}", width:"#{html_options[:width]}", height:"#{html_options[:height]}" };
        var par = #{par};
        var id = "#{html_options[:id]}";
        var myObject = swfobject.createSWF(att, par, id);
      };
      swfobject.addDomLoadEvent(fn);
    )
  )
  # FlashLoader.create('#{html_options[:id]}',#{base_options.to_json},'#{vars}',#{flash_options.to_json})
end
#Returns array of localized month names from locale yml file
# Accepted options:
# * <tt>:capitalize</tt> - if option passed all the month names will be capitalized
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
#:nodoc:
def cms_text_value_html_from_element element
  if !element.is_a?(String) && element.respond_to?("last")
    [element.first,element[1],element.last]
  else
    [element,element]
  end
end

#Converts html_option hash into string. Useful when appending options directly in html element.
# ====Example
#%(<a #{cms_html_options(options[:html]}/>Link</a>)
def cms_html_options html
  if Hash===html
    options=""
    html.each{|key,value|
      options<<%(#{key}="#{html_escape(value.to_s)}" ) if value
    }
    options
  end
end
#Creates a list of html options for select dropdown
# Accepted parameters:
# * <tt>container</tt> - Array containing array of values and text of the option elemnt
# * <tt>selected</tt> - value or array of values to be selected
# * <tt>escaped</tt> - if false option text content will not be escaped. default = true
# ====Example
#content_tag("select",cms_options_for_select([["day",1],["week",7],["month",30],["year",365]], [7]))
def cms_options_for_select container,selected=nil,escaped=true
  container = container.to_a if Hash === container
  options_for_select = container.inject([]) do |options, element|
    text, value, html = cms_text_value_html_from_element element
    if (selected.is_a?(Array) && selected.include?(value)) || selected==value
      selected_attribute = ' selected="selected" '
    end
    html_options=cms_html_options html
    options << %(<option #{html_options} value="#{html_escape(value.to_s)}"#{selected_attribute}>#{escaped ? html_escape(text.to_s) : text.to_s}</option>)
  end
  options_for_select.join("").html_safe!
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
  
#  def month_name nr, loc="kas?"
#    m=[{"Janvār"=>1},{"Februār"=>1},{"Mart"=>0},{"Aprīl"=>1},{"Maij"=>0},
#      {"Jūnij"=>0},{"Jūlij"=>0},{"August"=>0},{"Septembr"=>1},{"Oktobr"=>1},
#      {"Novembr"=>1},{"Decembr"=>1}
#    ]
#    dekl=[
#      {"kas?"=>"s","kā?"=>"a","kam?"=>"am","ko?"=>"u","kur?"=>"ā"},
#      {"kas?"=>"is","kā?"=>"a","kam?"=>"im","ko?"=>"i","kur?"=>"ī"}
#    ]
#    "#{m[nr-1].keys.first}#{dekl[m[nr-1].values.first][loc]}"
#  end
#
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
  title.html_safe!
end
def list_start_tags
  '<div class="m"><div class="b"> <div class="t"> <div class="l"><div class="r">
     <div class="br"> <div class="bl"> <div class="tr"><div class="tl">'.html_safe!
end
def list_end_tags
  "</div></div></div></div></div></div></div></div></div>".html_safe!
end
def javascript_response
  content_tag('div',
      content_tag('div',
      content_tag('div',"",:class=>'r',:id=>"javascript_response_content"),
      :class=>'l'),
      :class=>'greenbox',:id=>"javascript_response",:style=>"display:none;"
  ).html_safe!
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
  (result || "").html_safe!
end
  
def user_link
  link_to current_user.email,{:action=>'edit_self',:controller=>'/admin/user',:id=>current_user.id},{:class=>"grey", :style=>params[:action]=="edit_self" ? "text-decoration:underline" : ""} if current_user
end
 
def checkbox value,id
  chck=(value)?"checked='checked'":""
  id=(id)?("id=#{id}"):""
  "<input #{id} type='checkbox' '#{chck}' />".html_safe!
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

# insteed of <%= yield :main_content %> you do
# <% default_content_for :main_content do %>
#   <p>This is default content</p>
# <% end %>
def default_content_for(name, &block)
  name = name.kind_of?(Symbol) ? ":#{name}" : name
  out = eval("yield #{name}", block.binding)
  concat(out || capture(&block)).html_safe!
end

end

