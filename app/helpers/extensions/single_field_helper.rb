# coding:utf-8
module Extensions::SingleFieldHelper

  def create_counter id, options={},html={}
    counter="#{options[:title]%html[:maxlength]}"
    "<span id='#{id}_counter'>#{counter}</span>"+javascript_tag("new ITH.Editor.TextareaCounter('##{id}')")
  end
  
  def create_statusbar id, options={},all_options={}
    bar=""
    if options[:counter]
      bar<<create_counter(id,options[:counter],all_options[:html])
    end
    %(<div id="#{id}_statusbar">#{bar}</div>)
  end
  
  def cms_textarea object,options
    options[:html][:cols]||=50
    options[:html][:class]||="textarea"
    options[:html][:class]="#{options[:html][:class]} textarea-#{object}" unless options[:simple]
    if options[:simple] && options[:statusbar]
      status_bar=create_statusbar("#{object}_#{options[:field]}",options[:statusbar],options)
    end
    "#{text_area object, options[:field], options[:html]}#{status_bar} <br/>"
  end
  
  def cms_content_tree_field object,options
    if menu=Admin::Menu.web_menu("Admin").first #Valdis: atejam no namespecotā menu - if menu=Admin::Menu.web_menu(params[:controller].split("/").first).first
      id=params[:action]=='update' ? instance_variable_get("@#{object}").id : 0
      menu_items=menu.all_menu_items
      mi=[[t(:"fields.not_related"),0]]
      menu_items.each{|item|
        mi<<["#{'--'*(item.level-1)}#{item.name}",item.id]
      }
      current_menu=Admin::MenuItem.find(:first,:conditions=>["menuable_type=? and menuable_id=? and menu_id=?",@config[:object_name].camelize,id>0 ? id : -1,menu.id])
      current_menu_id=params[:menu_item_id] ? params[:menu_item_id].to_i : (current_menu ? current_menu.id : 0)
      content_tag("table",content_tag("tr",
          content_tag("td",
            content_tag('input',"",:type=>"hidden",:value=>menu.id,:name=>"object[menu_record][menu_id]")+
              select_tag("object[menu_record][branch]",options_for_select(mi,current_menu_id),:style=>"width:300px;")
          )+
            content_tag("td",
            image_tag("/lolita/images/cms/arrow_blue_s.gif",:alt=>"",:onclick=>"toggle_tree_arrows(this)")
          )+
            content_tag("td",
            content_tag("input","",:id=>"object_menu_record_new",:name=>"object[menu_record][new]",:class=>"txt",:style=>"width:211px;")+
              content_tag('input',"",:value=>"s",:type=>"hidden",:id=>"object_menu_record_dir",:name=>"object[menu_record][dir]")
          )
        ))
    end
  end

  def cms_custom_field object,options
    out=""
    if options[:function]
      if options[:args]
        options[:args].collect!{|element|
          if element.is_a?(String)
            "'#{element}'"
          else
            "#{element}"
          end
        }
      end
      #TODO ielikt speciālās funkcijas atbilstošajos modeļos
      out<<(eval("#{options[:function]}(#{instance_variable_get("@#{object}").id || 0},'#{options[:field]}',#{object},#{options[:args] ? options[:args].join(",") : "1"})")).to_s
    end
    out
  end

  def cms_label_field object,options
    if options[:table]
      obj=options[:table].camelize.constantize
      object=obj.find(instance_variable_get("@#{object}").send("#{options[:table]}_id"))
    else
      object=instance_variable_get("@#{object}")
    end
    if options[:titles] && options[:titles].is_a?(Array)
      result=field_to_string_simple(options[:titles],object)
    else
      if options[:titles]
        result=object.send(options[:titles])
      elsif options[:value]
        result=options[:value]
      end
    end
    content_tag('input',result,:type=>"text",:readonly=>"readonly",:class=>"txt")
    "<span class='object-label'>#{result}</span>"
  end

  def cms_hidden_field object,options
    if options[:value] || options[:name]
      name=options[:name]||"object[#{options[:field]}]"
      "<input type='hidden' name='#{name}' value='#{options[:value]}'/>"
    else
      hidden_field object,options[:field],options[:html]
    end
  end
  
  def cms_text_field object,options
    text_field object, options[:field], options[:html]
  end

  def cms_checkboxgroup_field object,options
    base_element=instance_variable_get("@#{object}")
    elements=base_element ? base_element.send(options[:field]) : []
    remote_class=base_element.class.reflect_on_association(options[:field]).klass
    remote_elements=remote_class.find(:all,options[:find_options]) if remote_class
    result=""
    remote_elements.each{|element|
      r=check_box_tag("#{object}[#{options[:field]}][]", element.id,elements.include?(element),{:id=>"#{options[:field]}_#{element.id}"})
      r+=%(<label for="#{options[:field]}_#{element.id}" >#{field_to_string_simple(options[:titles],element)}</label>)
      result += "<div class=\"checkbox\">#{r}</div>"
    }
    result
  end
  
  def cms_select_field object,options
    options[:options] = options[:options].call if options[:options].is_a?(Proc)
    select_options=get_data_for_select_field(options).collect{|row| row[0].is_a?(Symbol) ? [t(row[0]),row[1]] : row}
    current_value=get_current_value_for_select_field(object,options)
    current_value=current_value.is_a?(Symbol) ? t(current_value) : current_value
    options[:html][:class]="select"
    options[:html][:class]=options[:parent_link] ? "select-parented" : options[:html][:class]
    if options[:unlinked]
      options[:html][:class]=options[:html][:class]+(options[:multiple] ? " multiple" : "")
      select_options=[["-",0]]+select_options if options[:include_blank]
      select_tag("#{object}[#{options[:field]}]#{options[:multiple] ? "[]" : ""}",options_for_select(select_options,current_value),options[:html].merge({:multiple=>options[:multiple]}))+
        ((options[:parent_link] && !options[:multiple])?(cms_link(image_tag("/lolita/images/icons/add.png",:alt=>"+"),'GET',:action=>'create',:controller=>((options[:namespace]?(options[:namespace]+"/"):"")+options[:field].to_s.sub( /_id/, "")), :params=>{:set_back_url=>true},:html=>{:class=>'object-select-add'})):"")+
        (options[:multiple] ? "<br/><sup class='detail'>#{"lai iezīmētu vairākas rindas turiet nospiestu Crtl"}</sup>" : "")
    else
      "<table><tr>"+
        content_tag('td',select(object.to_sym,options[:field].to_s,select_options,{:include_blank=>options[:include_blank],:selected=>current_value}, options[:html]))+
        ((options[:parent_link])?(content_tag('td',cms_link(image_tag("/lolita/images/icons/add.png",:alt=>"+"),'GET',:action=>'create',:controller=>((options[:namespace]?(options[:namespace]+"/"):"")+options[:field].to_s.sub( /_id/, "")), :params=>{:set_back_url=>true},:html=>{:class=>'object-select-add'}))):"")+
        "</tr></table>"
    end
  end

  def get_current_value_for_select_field object,options={}
    if options[:without_default_value]
      nil
    else
      if options[:default_value]
        options[:default_value]
      else
        obj=instance_variable_get("@#{object}")
        obj.send(options[:field].to_s) if obj
      end
    end
  end
  
  def get_data_for_select_field options={}
    data=options[:options] || options[:table].to_s.camelize.constantize.find(:all,options[:find_options])
    options[:simple] ? data : cms_simple_options_for_select(data,options[:titles])
  end
end
