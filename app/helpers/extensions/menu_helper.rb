module Extensions::MenuHelper
  def menu_item_link_to (item,current_branch,options={})
    picture=item.pictures.main_or_first if options[:image]
    title=options[:image] && picture ? image_tag(picture.picture.url) : item.name
    link_to(title,item.link,{:class=>(current_branch.include?(item)  ? " active" : "")})
  end

  def get_current_menu_branch (menu_name)
    cur_in_menu = get_current_menu_item(menu_name)
    if cur_in_menu
      cur_in_menu.self_and_ancestors
    else
      []
    end
  end

  def get_current_menu_item(menu_name)
    id = get_id
    if params[:name] && params[:controller]=="Cms::DynamicForm"
      df=DynamicForm.find_by_template(params[:name])
      id=df ? df.id : nil
    end
    type = params[:controller].camelize
    #if type=="Cms::StartPage"
    #  menu_items = Admin::Menu.find_by_menu_name(menu_name).menu_items.find(:all, :conditions=>['menuable_type=? AND is_published=1',type])
    if id
      menu_items = Admin::Menu.find_by_menu_name(menu_name).menu_items.find(:all, :conditions=>['menuable_type=? AND menuable_id=? AND is_published=1',type,id])
    else
      return nil
    end
    menu_item=menu_items.empty? ? nil : Admin::MenuItem.get_deepest_item(menu_items)
    unless menu_item
      menu_item=get_menu_item_with_action(menu_name)
    end
    unless menu_item
      object=type.constantize
      menu_item=object.find_related_menu_item(menu_name,id)      
      unless menu_item
        menu_item = session["last_selected_#{menu_name.downcase}_item"] unless session["last_selected_#{menu_name.downcase}_item"].nil? 
      end
    else
      session["last_selected_#{menu_name.downcase}_item"] = menu_item
    end
    menu_item
  end

  def get_menu_item_with_action(menu_name)
    menu=Admin::Menu.find_by_menu_name(menu_name)
    menu_items=menu ? menu.action_item(params) : []
    menu_items.empty? ? nil : Admin::MenuItem.get_deepest_item(menu_items)
  end
  
  def get_menu_editors(id,namespace,object,menu_id)
    if Admin::Menu.exists?(menu_id)
      menu=Admin::Menu.find(menu_id)
      menu_type=menu.menu_type
    end
    menu_item=Admin::MenuItem.find_by_id(id) 
    case menu_type
    when 'app',menu.menu_name=='admin'
      admin_menu_select menu_item,namespace,menu_id
    when 'web'
      content_menu_select menu_item,namespace,menu_id
    when 'public_web'
      public_web_menu_select menu_item,namespace,menu_id
    end
  end

  def menu_select_name namespace, method="table"
    namespace ?  "object[#{namespace}][#{method}]" : "object[#{method}]"
  end
  
  def admin_menu_select menu_item,namespace,menu_id
    #action_name=namespace ?  "object[#{namespace}][action]" : "object[action]"
    if menu_item && menu_item.menuable_type=='Admin::Action'
      current_table= menu_item.menuable.controller ? menu_item.menuable.controller : ""
      current_action=menu_item.menuable.action
    end
    if current_table
      begin
        controller="#{current_table}_controller".camelize.constantize
        allowed_actions=controller.default_actions+controller.system_actions
        allowed_actions.collect!{|action|
          name=action.first.is_a?(Symbol) ? t(action.first) : action.first
          name=name.to_s.size>0 ? name : nil
          [name || action.last.to_s.humanize, action.last]
        }
      rescue
        allowed_actions=[[t(:"fields.not selected"),-1]]
      end
    else
      allowed_actions=[[t(:"fields.not selected"),-1]]
    end
    render :partial=>"admin_menu_select", :locals=>{
      :table_options=>options_for_select(get_tables_for_menu(menu_id,{:all=>true}),current_table),
      :action_options=>options_for_select(allowed_actions,current_action),
      :namespace=>namespace,
      :current_item_id=>menu_item ? menu_item.id : 0
    }
  end

  def content_menu_select menu_item,namespace,menu_id
    current_table=menu_item.menuable_type.underscore if menu_item && menu_item.menuable_type
    incl=[['Sākums','home']]
    select_tag(menu_select_name(namespace),options_for_select(get_tables_for_menu(menu_id,{:simple=>true,:include=>incl}),current_table),:class=>"select")
  end
  
  def public_web_menu_select menu_item,namespace,menu_id
    public_menu=Admin::Menu.find_by_id(menu_id)
    menu = public_menu ? Admin::Menu.web_menu(public_menu.module_name).first : nil
    return "" unless menu
    menu_items=menu.all_menu_items
    items=[["-Nav norādīts-",0]]
    menu_items.each{|item|
      items<<["#{'--'*(item.level-1)}#{item.name}",item.id]
    }
    if menu_item && menu_item.menuable_type && menu_item.menuable_type!="Admin::Action" && menu_item.url.to_s.size<1
      current_item=menu.menu_items.find(:first,:conditions=>["menuable_type=? and menuable_id=?",menu_item.menuable_type,menu_item.menuable_id])
      current_item=current_item ? current_item.id : 0
    elsif menu_item && menu_item.menuable_type=="Admin::Action" && menu_item.menuable
      current_action=menu_item.menuable.action
      current_table=menu_item.menuable.controller
      controller="#{current_table}_controller".camelize.constantize
      allowed_actions=controller.public_actions.collect!{|action|
        name=action.first.is_a?(Symbol) ? t(action.first) : action.first
        name=name.to_s.size>0 ? name : nil
        [name || action.last.to_s.humanize, action.last]
      }
    elsif menu_item && menu_item.url.to_s.size>0
      url=menu_item.url
    end
    render :partial=>"admin/menu_item/public_web_menu_select", :locals=>{
      :current=>current_action ? :action : (url ? :url : :content),
      :url=>url,
      :content=>{:options=>options_for_select(items,current_item),:name=>menu_select_name(namespace,"item")},
      :actions=>{
        :table_options=>options_for_select(get_tables_for_menu(menu_id),current_table),
        :action_options=>options_for_select(allowed_actions || [],current_action),
        :namespace=>namespace,
        :current_item_id=>menu_item ? menu_item.id : 0
      }
    }
 
  end
  
  def menu_splitter
    '<span >|&nbsp;</span>'
  end
end