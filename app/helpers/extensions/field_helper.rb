module Extensions::FieldHelper
  include Extensions::SingleFieldHelper

  # :roles=>{:include=>["editor"]}
  # :roles=>{:exclude=>{:edit=>["editor"]}
  def can_edit_field? field
    user=Admin::User.current_user
    allow_action=((!field[:actions])||(field[:actions] && field[:actions].include?(params[:action].to_sym)))
    if field[:roles]
      if field[:roles][:include].is_a?(Hash)
        include_roles=field[:roles][:include][params[:action].to_sym]
        has_role=include_roles ? include_roles.detect{|role| user.has_role?(role)} : true
      else
        include_roles=field[:roles][:include]
        has_role=include_roles ? include_roles.detect{|role| user.has_role?(role)} : true
      end
      if field[:roles][:exclude].is_a?(Hash)
        exclude_roles=(field[:roles][:exclude][params[:action].to_sym] || [])
        no_role=exclude_roles.detect{|role| user.has_role?(role)}
      else
        exclude_roles=(field[:roles][:exclude] || [])
        no_role=exclude_roles.detect{|role| user.has_role?(role)}
      end
    end
    allow_role=(user.is_admin? && (exclude_roles && !exclude_roles.detect{|role| role==Admin::Role.admin}) || !exclude_roles) || !field[:roles] || (field[:roles] && has_role && !no_role)
    allow_action && allow_role
  end
  
  def start_page_fields place
    table_name="object[#{place}]" 
    menu = Admin::Menu.web_menu(namespace).first
    menu_items=menu.all_menu_items
    items=[["-Izvēlieties sadaļu-",0]]
    menu_items.each{|item|
      items<<["#{'--'*(item.level-1)}#{item.name}",item.id]
    }
    sp=Cms::StartPage.find_by_place(place)
    mi=sp.menu_item if sp
    current_item= mi ? mi.id : 0
    select_tag(table_name,options_for_select(items,current_item),:class=>"start_page_select")
  end

  # Iespējams norādīt saliktu virsrakstu, kurš ir kā masīvs, kurā katrs masīva elements
  # var būt vai nu Symbol vai String.
  # Symbol tipa elementi tiek aizstāti ar attiecīgā objekta ar šādu lauku vērbību.
  # Piemērs.
  #     @object={:id=>1, :name=>"test"} - ActiveRecord objekts
  #     field_to_string_simple ["vārds_",:id],@object
  # => "vārds_1"
  # String tipa elementi netiek aizstāti, taču ja sākas ar : tad : un viss līdz
  # nākamajam ne burtam,skaitlim vai _ tiks aizstāts ar objekta funkcijas izsaukumu,
  # kas atbilst šim.
  # Piemērs.
  #     @object={:id=>1, :name=>"test"}
  #     field_to_string_simple [":name.gsub('t','')"]
  # => "es"
  def field_to_string_simple field,object
    result=""
    field.each{|value|
      if value.is_a?(Symbol)
        result+=object.send(value.to_s).to_s
      elsif value.is_a?(String) && value.match(/:\w+/)
        new_constr=value.gsub(/:\w+/){|field_name|
          "object.send('#{field_name.gsub(":","")}')"
        }
        result+=eval(new_constr) 
      else
        result+=value
      end
    }
    result
  end
  
  def cms_simple_options_for_select(data,titles)
    data.collect{|p|
      if titles && titles.is_a?(Array)
        title=field_to_string_simple(titles,p)
      else
        title=p.send(titles || 'name')
      end
      [title,p.id]
    } 
  end

  def get_tab(tab)
    tab.is_a?(Hash) ? tab : (@config[:tabs] ? @config[:tabs][tab] : nil)
  end

  def create_fields_for_js(fields)
    result=[]
    fields.each{|f_arr|
      f_arr[1].each{|f_obj|
        result<<[f_arr[0],{:field=>f_obj[:field],:type=>f_obj[:type],:simple=>f_obj[:simple]}]
      }
    }
    result
  end

  def fields_for_tab(tab)
    tab=get_tab(tab)
    if tab[:fields]
      (tab[:fields]==:default ? @config[:fields] : tab[:fields])
    else
      []
    end##obligāti jābūt fields
  end

  def tabs_fields tab=nil,options={}
    if tab.nil?
      if options[:with_object]
        @config[:tabs].inject([]){|result,tab|
          result<<[tab[:object] || :object,tabs_fields(tab,options)]
        }
      else
        @config[:tabs].inject([]){|result,tab|
          result=result+tabs_fields(tab,options)
        }
      end
    else
      tab=get_tab(tab)
      if tab[:fields] && (!options[:in_form] || tab[:in_form]==options[:in_form])
        ((tab && tab[:fields]==:default)) ? @config[:fields] : tab[:fields]
      else
        []
      end
    end
  end
  
  def is_field?(field_name,tab=nil)
    tabs_fields(tab).each{|value|
      if value[:type] && value[:type].to_sym==field_name.to_sym && !value[:simple]
        return true
      end
    }
    return false
  end
 
  # Lauks un tam norādāmie parametri
  # Kopējie
  #   :field - lauka nosaukums, tiek izmantots veidojot ievades lauku un dati tiek ielasīti no šāda tipa metodes (lielākoties)
  # :autocomplete
  #   :url - adrese no kuras nepieciešams ielādēt datus
  #   :html - html atribūti
  #   :class_name - klase, kuras dati tiek ielasīti vai ievadīti laukā
  #   :save_method - metode kura jāizmanto lai saglabātu datus atbilstošajai klasei
  #
  def field_render (type,options={})
    options[:html]||={}
    object=options[:object] ? options[:object] : :object
    case type.to_sym
    when :autocomplete
      autocomplete_field(object,options[:field],options[:url],options.delete_if{|key, value| key == :url } )
    when :content_tree
      cms_content_tree_field(object,options)
    when :custom
      cms_custom_field(object,options)
    when :list
      render :partial=>"/managed/remote_list", :locals=>{:fields=>options[:fields],:parent=>@config[:object_name],:id=>@object.id}
    when :label
      cms_label_field(object,options)
    when :hidden
      cms_hidden_field(object,options)
    when :text
      options[:html][:class]||="txt"
      cms_text_field(object,options)
    when :password
      password_field object,options[:field],options[:html]
    when :number
      options.delete(:field)
      number_field object, options[:field], options[:html]
    when :date
      date_select object, options[:field], options[:config],options[:html]
    when :datetime
      datetime_select object,options[:field],options[:config],options[:html]
    when :checkbox
      options[:html][:class]||="txt"
      check_box object,options[:field],options[:html]
    when :textarea
      cms_textarea object,options
    when :select
      cms_select_field object,options
    when :checkboxgroup
      cms_checkboxgroup_field object,options
    else
      ""
    end
  end
end
