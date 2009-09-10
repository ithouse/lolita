# 
# SIA ITHouse
# Artūrs Meisters
module ManagedHelper
  include Extensions::FieldHelper
  include Extensions::PagingHelper
  include Extensions::LinkHelper
  include Extensions::TranslationHelper

  def render_partials position
    partials=@config[:list][:partials][position] if @config[:list] && @config[:list][:partials]
    partials || []
  end
  
  def render_list_filters obj
    if @config[:list] && @config[:list][:parent_filter] && @config[:list][:parent_filter].is_a?(Array)
      @config[:list][:parent_filter].each{|p_filter|
        filters=render_list_filter p_filter,obj
        yield filters if filters
      }
    elsif @config[:list]
      filters=render_list_filter @config[:list][:parent_filter],obj
      yield filters if filters
    end
  end

  def render_list_filter filter,obj
    if filter.is_a?(String)
      return render(:partial=>filter, :object=>obj)
    elsif filter
      filters=""
      parent_filter(@config[:object_class].to_s.underscore) do |switch,filter_options|
        filters<<%(<select class="select parent_filter_select" onchange="#{switch}">#{filter_options}</select>)
      end
      return filters
    else
      return nil
    end
  end
  
  def object_variable tab=nil
    tab=get_tab(tab)
    tab && tab[:object] ? instance_variable_get("@#{tab[:object]}") : @object
  end
  
  def default_cms_columns
    obj=@object ? @object.class : params[:controller].camelize.constantize
    obj.columns.inject([]){|result,column|
      width=760/obj.columns.size + ([:string,:datetime].include?(column.type) ? 50 : (-50))
      result<<{:width=>width,:title=>column.name.humanize,:field=>column.name,:default=>obj.columns.first==column,:link=>true,:sortable=>true}
    }
  end
  
  def tabs options={}
    opened=false
    media_types=Media::FileBase.all_media_names.collect{|m| m.to_sym}
    special_types= [:metadata,:translate,:multimedia]
    @config[:tabs].each_with_index{|tab,index|
      tab[:index]=index
      tab_opened=(!opened || tab[:opened_on_load]) && (tab[:opened])
      opened=tab_opened ? true : opened
      start_html,end_html=tab_start_end_html(tab,index,tab_opened)
      tab[:partial]="/managed/object_data" if tab[:type]==:content || tab[:type]==:default
      unless special_types.include?(tab[:type])
        yield %(#{start_html}#{render(:partial=>tab[:partial],:locals=>{:tab=>index})}#{end_html}) if options[:in_form]==tab[:in_form]
      else
        if tab[:type]==:metadata
          yield %(#{start_html}#{render(:partial=>"/managed/meta_information",:locals=>{:tab=>index})}#{end_html}) if options[:in_form]
        elsif tab[:type]==:translate
          yield %(#{start_html}#{render(:partial=>"/managed/translate",:locals=>{:tab=>index})}#{end_html}) if is_translatable?(options)
        elsif tab[:type]==:multimedia && media_types.include?(tab[:media])
          if self.respond_to?(:"lolita_#{tab[:media]}_tab")
            yield "#{start_html}#{self.send("lolita_#{tab[:media]}_tab",options,tab)}#{end_html}"
          else
            yield "#{start_html}#{default_lolita_media_tab(options,tab)}#{end_html}"
          end
        end
      end
    }
  end

  def set_map_hidden_fields(object,method)
    locations=object.send(method)
    if locations.is_a?(Array)

    else
      %(<input type="hidden" name="location[lat]" value="#{locations.lat if locations}" id="object_map_lat"/>
        <input type="hidden" name="location[lng]" value="#{locations.lng if locations}" id="object_map_lng"/>)
    end
    
  end
  def is_translatable? options={}
    options[:in_form] && Lolita.config.translation &&  params[:action]=="update"
  end
  def tab_start_end_html tab,index,opened=nil
    start_html=%(<div id="tab#{index}container" name="tab_content" style="display:#{opened ? "block" : "none"};">)
    tab[:partials][:before].each{|before_partial|
      start_html+=render(:partial=>before_partial,:locals=>{:tab=>index})
    } if tab[:partials] && tab[:partials][:before]
    end_html=""
    tab[:partials][:after].each{|after_partial|
      end_html+=render(:partial=>after_partial,:locals=>{:tab=>index})
    } if tab[:partials] && tab[:partials][:after]
    end_html+=%(<br class="clear"/><div><!--[if !IE]>for ie to expand height correctly<![endif]--></div></div>)
    return start_html,end_html
  end

  def add_fields_html()
    @config[:tabs].each{|tab|
      fields=fields_for_tab(tab)
      fields.each{|field|
        if field[:type].to_sym==:autocomplete && field[:add_new] && can_edit_field?(field)
          yield %(
          <div id="#{tab[:object]||:object}_#{field[:field]}_autocomplete_dialog" style="visibility:hidden">
              <div class="hd">#{t(:"fields.autocomplete.header")}</div>
              <div class="bd">
                <form method="POST" action="#{url_for(field[:add_new])}">
                  <label for="subject">#{t(:"fields.autocomplete.tag name")}:</label>
                  <input type="text" name="object[name]" size="30" maxlength="255" style="margin-bottom:3px;"/><br/>
                  <input type="button" class="btn" id="#{tab[:object]||:object}_#{field[:field]}_autocomplete_dialog_confirmation_button" value="#{t(:"actions.confirm")}"/>
                  <input type="button" class="btn" id="#{tab[:object]||:object}_#{field[:field]}_autocomplete_dialog_cancel_button" value="#{t(:"actions.cancel")}"/>
                </form>
              </div>
          </div>
          )
        end
      } if fields.respond_to?(:each)
    }
  end
  
  def tab_headers
    opened=nil
    @config[:tabs].each_with_index do |tab,index|
      tab_opened=tab[:opened] && !opened
      opened=tab_opened || opened
      tab[:title]=t(tab[:title]) if tab[:title] && tab[:title].is_a?(Symbol)
      if tab[:type]!=:translate || (tab[:type]==:translate && is_translatable?(:in_form=>true))
        yield tab_header(tab[:title] || (tab[:media] ? t(:"tabs.#{tab[:media]}") : t(:"tabs.#{tab[:type]}")), :index=>index,:current=>tab_opened)
      end
    end
  end

  def tab_header title,options={}
    index=options[:index]||rand
    current=options[:current] ? "current" : ''
    "<a id='tab#{index}' name='tab_header' class='#{current}' onclick="+'"'+"switch_tabs(this)"+'"'+">#{title}</a>"
  end

  #ja ir simbols tad uztvers kā tulkojamu objektu, ja vajag lauku tad jānorāda kā String
  #simbolam arī ir jāiekļauj punkts, jo pašlaik sistēmā visi tulkojumi tiek dalīti grupās
  def field_title field=nil,controller=nil
    if field.is_a?(Symbol) && field.to_s.split(".").size>1
      t(field)
    else
      Admin::Field.by_table_and_field(controller || (@config ? @config[:parent_name] : nil) || params[:controller],field) if field
    end
  end

  def table_title controller
    table=Admin::Table.find_by_name(controller)
    table ? table.humanized_name : controller.humanize
  end
  def list_header options={}
    #TODO izveidot lai tiek ģenerēts no list[:columns]
  end

  def list_header_cell options={}
    #current_class=(@config[:parent_name] || params[:controller].camelize.constantize.name.underscore).to_sym
    options[:params]||={}
    options[:html]||={}
    options[:html][:class]||="black"
    options[:params][:sort_direction]||=sort_direction
    options[:params][:sort_column]||=options[:sort_column] ? options[:sort_column].to_s : nil
    options[:container]||="form_list"
    options[:title]||=field_title(options[:params][:sort_column] || options[:title])
    content=(@config[:list][:sortable] && options[:params][:sort_column] ? list_link(options) : options[:title])+"&nbsp;"
    content+=(
      if @config[:list][:sortable] && (options[:params][:sort_column] &&  (params[:sort_column] || session[current_session_name][:sort_column] || []).include?(options[:params][:sort_column]))
        if options[:params][:sort_direction]=="asc"
          image_tag("/lolita/images/cms/arrow_blue_s.gif",:alt=>"V")
        else
          image_tag("/lolita/images/cms/arrow_blue_n.gif",:alt=>"A")
        end
      else
        image_tag("/lolita/images/cms/bullet_blue.png",:alt=>"o")
      end
    )
    content_tag("th", content,:style=>options[:width] ? "width:#{options[:width]}px;" : nil)
  end

  def small_list_header_cell options={}
    %(<th class="small-table-header" style="width:#{options[:width] || 70}px;">#{field_title(options[:title], options[:controller])}</th>)
  end
  def cms_flash_box
    if flash[:notice]
      %(<div class="greenbox">
        <div class="l">
          <div class="r">
            #{t(flash[:notice])}
          </div>
        </div>
      </div>
      <br class="clear" />
      )
    end
  end
  def list_options element
    @config[:list][:options].each{|option|
      case option
      when :edit
        yield edit_link(:id=>element.id,:image=>true)
      when :destroy
        yield destroy_link(:id=>element.id, :image=>true)
      when :info
        yield infolink(element)
      else

        #        reflection=option.to_s.gsub("link_to")
        #        table=Admin::Table.find_by_name("#{namespace}/#{reflection.singularize}")
        #        human_name=table.human_name if table && table.human_name.to_s.size>1
        #        link_name=human_name ? human_name.daudzskaitlis : human_name.pluralize
        #        yield list_link(:title=>"#{link_name.humanize}(#{element.send(reflection).count})",:controller=>"/#{namespace}/#{reflection.singularize}",:action=>:list, "#{only_controller}_id".to_sym=>element.id)
      end
    } if @config[:list][:options]
  end

  def hash_to_hash(source,destination,excluded=[],overwrite=false)
    if source.respond_to?("each") && destination.is_a?(Hash)
      source.each{|key,value|
        unless excluded.include?(key) || (source[key] && !overwrite)
          destination[key]=value
        end
      }
    end
    destination
  end
  
  def get_remote_data table,parent,id
    obj=parent.camelize.constantize
    if obj.exists?(id)
      obj=obj.find(id)
      met=table.pluralize
      obj.send(met)
    else
      false
    end
  end
  
  def has_relation?(related_id=0,related_table="")
    @object.send(related_table.pluralize).exists?(related_id)
  end
  
  def cms_title name
    table=Admin::Table.find_by_name(name)
    name=name.gsub(/\//,"_")
    human_name= table && table.human_name.to_s.size>0 ? table.human_name : nil
    case params[:action]
    when "create"
      if human_name
        I18n.locale == :lv ? "Jaun#{human_name.match(/[sš]$/) ? "s" : "a"} #{human_name.downcase}" : "#{t(:"actions.new")} #{human_name.downcase}"
      else
        "New #{name.humanize.downcase}"
      end
    when "update"
      if human_name
        I18n.locale == :lv ? "Labot #{human_name.locit("ko?")}" : "#{t(:"actions.edit")} #{human_name.downcase}"
      else
        "Edit #{name.humanize.downcase}"
      end
    when "list"
      words=human_name.split(" ") if human_name
      last_word=words.pop if words
      if human_name
        I18n.locale == :lv ? "#{words.join(" ")} #{last_word.daudzskaitlis}" : human_name.pluralize
      else
        name.humanize.pluralize
      end

    end
  end

  def form_submit_action
    result="submitForm(\"#object_form\",\"#{@config[:on_complete].gsub(/'/,"\\\\\"")}\");"
    result
  end # ;submitForm('#object_form','#{@config[:on_complete]}');
  #  def on_submit_action
  #    "setRemoteFormParams(#{tabs_fields(nil,:in_form=>true).to_json})"
  #  end
  def on_delete_submit
    "setDeleteFormParams()"
  end
  def on_submit_action_with_ids(options=[])
    arr={}
    counter=1
    options.each{|val|
      arr[counter.to_sym]={:type=>'textarea',:field=>val}
      counter+=1
    }
    "setRemoteFormParams(#{arr.to_json})"
  end
  
  def feedback
    request.request_uri.include?("?")?"&redirected=true":"?redirected=true"
  end

  def send_method_array element,ary
    tempobj=element
    ary.each{|meth|
      begin
        tempobj=tempobj.send(meth)
      rescue
        raise "Error sending #{meth}, check managed list config :field for #{element}.#{ary.join(".")}"
      end
    }
    tempobj
  end
end

