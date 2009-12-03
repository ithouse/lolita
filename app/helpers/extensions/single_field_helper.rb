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
      r=check_box_tag("#{object}[#{options[:field]}_ids][]", element.id,elements.include?(element),{:id=>"#{options[:field]}_#{element.id}"})
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

  # renders a has_and_belongs_to_many relationship in form of a
  # list of existing associated records and <select> of other possibilities
  #
  # field - attribute to access associated objects,
  #  should be of {singularized}_ids form, e.g. :equipment_ids
  #  or will be autoconverted from pluralized form, e.g. :equipments=>:equipment_ids
  # optional parameters:
  # :title - to use for label, default t(".{field}")
  # :object - parent object, e.g. :product, default is 'object'
  # :existing - an array of [title,id,[css_class]] for display of existing items in the list
  #  or :symbol of method to get them for current object
  #  if absent, expects "@{:object}" variable to be present and collects
  #  [{:property},{singularized property}] of the plularized form of specified field
  #  e.g. field=product_ids,{:object=>:batch,:property=>:price} results in
  #   :existing=>@batch.products.collect{|product| [product.price,product.product_id]}
  # :property - only used in case of missing :existing
  #
  # :suggest - an array of [title,value,[css_class]], usually object.attribute less :existing
  #  other possible elements in the control select
  #  or :symbol method to return such array
  #
  # :possible - if :suggest absent, collection of elements to filter :suggest from
  #   e.g. :existing=>@batch.products.collect{...},:possible=>Products.all
  # if both :suggest and :possible are absent, {field}.all is assumed
  #  e.g. multi_select(:car_class_ids)
  #   :existing=>@object.car_classes ...
  #   :possible=>CarClass.all
  #   :suggest=>:possible less :existing by comparing their ids
  # :maximum - max elelements allowed,
  #   model should contain according validates_length_of attributes,:maximum=>?
  # :limit - {:class_name=>number, ...}
  #  additional limit on specific elements can be set via assigning them a css class name
  #  in both existing and suggest elements
  #  list automatically switches to numbered on display
  # :template - future element template to use instead of standard,
  #  placeholders for {text}, {attr}, {value} will be substituted by javascript
  #
  # samples:
  #
  # show list of existing @object.equipments and other possible from Equipment.all:
  # multiedit_select(:equipments)
  #
  # multiedit_select(:equipment_ids,
  #  t(:".car_equipments"),
  #  :maximum=>CarClass::maximum_equipment_count,
  #  :existing=>@object.equipments.collect{|equip|
  #    [
  #      "#{equip.name}#{equip.is_combo? ? ' (combo)':''}",
  #      equip.equipment_id,
  #      equip.is_combo? ? 'combo' : ''
  #    ]},
  #  :suggest=>Equipment.excluding(@object.equipments).collect{|equip|
  #    [
  #      "#{equip.name}#{equip.is_combo? ? ' (combo)':''}",
  #      equip.id,
  #      equip.is_combo? ? 'combo' : ''
  #    ]
  #  },
  #  :limit=>{:combo=>3}
  #)
  def cms_multi_select_field(hsh={})
    field=hsh[:field]
    field="#{field.to_s.singularize}_ids" unless field.to_s.match('_ids')
    hsh[:title]||=t(".#{field}")
    hsh[:object]||='object'
    hsh[:attribute]||=field
    hsh[:property]||=:name
    [:existing,:suggest].each{|key|
      hsh[key]=eval("@#{hsh[:object]}").send(hsh[key]) if hsh[key].is_a?(Symbol)
    }
    hsh[:existing]=eval("@#{hsh[:object]}").
      send( hsh[:attribute].to_s.gsub('_ids','').pluralize ).collect { |item|
      [item.send(hsh[:property]),item.send(hsh[:attribute].to_s.singularize)]
    } if hsh[:existing].nil?
    hsh[:possible]=hsh[:attribute].to_s.gsub('_ids','').
      camelize.constantize.all if hsh[:suggest].nil? && hsh[:possible].nil?
    if hsh[:suggest].nil? && hsh[:possible]
      ids=hsh[:existing].collect {|option| option[1] }
      filtered=hsh[:possible].reject { |item| ids.include?(item.id) }
      hsh[:suggest]=filtered.collect {|item| [item.send(hsh[:property]),item.id]}
    end
    render(:partial=>"managed/multi_select",:locals=>{:hsh=>hsh},:layout=>false)
  end

  # allows editing/creating has_many associated records
  #
  # field - attribute to access associated objects,
  #  should be of pluralized form, e.g. :equipment_options
  # optional parameters:
  # :title - to use for label, default t(".{field}")
  # :object - parent object e.g. :product, default is :object
  # :property - attribute of the bound object for input, default :name
  # :existing - an array of [title,id] for display of existing items in the list
  #  if absent, expects "@{:object}" variable to be present and collects
  #  [{:property},id] of the specified field
  #  e.g. multi_input(:products,:object=>:batch,:property=>:price) results in
  #   :existing=>@batch.products.collect{|product| [product.price,product.id]}
  # :maximum - max elelements allowed,
  #   model should contain according validates_length_of attributes,:maximum=>?
  # :template - future element template to use instead of standard,
  #  placeholders for {text}, {attr}, {value} will be substituted by javascript
  #
  # NOTE: if you need to override how the values are manipulated,
  # create according methods in your model that are named:
  #  multi_input_new_{attr}= (e.g. multi_input_new_products=)
  #  multi_input_existing_{attr}=
  #  multi_input_deletable_existing_{attr}=
  def cms_multi_input_field(hsh={})
    hsh[:title]||=t(".#{hsh[:field]}")
    hsh[:object]||='object'
    hsh[:attribute]||=hsh[:field]
    hsh[:property]||=:name
    [:existing,:suggest].each{|key|
      hsh[key]=eval("@#{hsh[:object]}").send(hsh[key]) if hsh[key].is_a?(Symbol)
    }
    hsh[:existing]=eval("@#{hsh[:object]}").send(hsh[:attribute]).collect { |item|
      [item.send(hsh[:property]),item.id]
    } if hsh[:existing].nil?
    render(:partial=>"managed/multi_input",:locals=>{:hsh=>hsh},:layout=>false)
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
