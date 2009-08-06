class Admin::MenuController < Managed
  allow :all=>[
    :init_menus,
    :refresh,
    :public_menus,
    :toggle_publish,
    :init_translations,
    :get_updated_items
  ]
 
  def init_menus
    response=""
    Admin::Menu.init_menus(params[:namespace]) do |app,web|
      response+="new ITH.MenuTree('app_editable_menu',#{app[:configuration].to_json},#{app[:data].to_json},null,'#{form_authenticity_token}');"
      response+="new ITH.MenuTree('web_editable_menu',#{web[:configuration].to_json},#{web[:data].to_json},null,'#{form_authenticity_token}');" if web
    end
    render :text=>response
  end

  def init_translations
    translations=Admin::Menu.tree_translations
    translations.each{|key,value|translations[key]=t(value)}
    render :json=>translations,:layout=>false
  end
  
  def public_menus
    menus=Admin::Menu.public_menus(params[:namespace]).collect{|menu|
      {:id=>menu.id,:name=>menu.menu_name}
    }
    menus=[{:id=>0,:name=>t(:"menu.field.public menus")}]+menus
    render :text=>menus.to_json
  end
  
  def public_menu
    menu=Admin::Menu.find_by_id(params[:id])
    if menu
      render :text=>"[#{menu.configuration.to_json},#{menu.tree_data.to_json}]"
    else
      render :text=>"Error",:status=>404
    end
  end
  
  def get_updated_items
    old_time=Time.parse(params[:current_time])
    render :text=>[Time.now,Admin::MenuItem.updated_items(old_time,params[:menu_id])].to_json
  end
  
  def refresh
    menu=Admin::Menu.find_by_id(params[:id])
    if menu
      render :text=>menu.tree_data.to_json
    else
      render :text=>"Kļūda", :status=>404
    end
  end
  
  def content_map
    web_menu=Admin::Menu.web_menu(params[:namespace]).first
    @web={
      :configuration=>web_menu.configuration.merge({:links=>true}),
      :data=>web_menu.tree_data
    } 
    render :layout=>false
  end
  def save_full_tree
    menu=Admin::Menu.find_by_menu_name(params[:menu_name])
    menu.save_full_tree(params[:tree]) if menu
    render :text=>"ok"
  end
  
  def toggle_published
    item = Admin::MenuItem.find(get_id)
    item.is_published = !item.is_published
    item.save
    render :text=>item.is_published ? 1 : 0, :layout=>false
  end
  
  def add_content
    content_item=Admin::MenuItem.find_by_id(params[:content_id])
    public_item=Admin::MenuItem.find_by_id(params[:public_id])
    public_item_parent=Admin::MenuItem.find_by_id(params[:public_parent_id])

    if content_item  && public_item_parent
      public_item=public_item_parent.update_or_create_public_item(public_item,content_item.name,params[:status],params[:parent_id])
      removed_items=public_item.add_public_content(content_item, public_item.name)
      if public_item
        response=[public_item.branch_data]+removed_items.collect{|item| item.branch_data}
        render :text=>response.to_json
      else
        render :text=>"Kļūda", :status=>404
      end
    else
      render :text=>"Kļūda", :status=>404
    end
  end
  
  def remove_content
    item = Admin::MenuItem.find(get_id)
    render :json=>item.remove_content
  end
  
  def add_public_menu
    if params[:name] && params[:name].size>0
      #new_name = params[:name].gsub(/ /, '_').gsub(/([^a-zA-Z_])/,'')
      new_name=params[:name]
      old_menu=Admin::Menu.public_menu(params[:namespace],new_name).first
      unless old_menu
        menu = Admin::Menu.create({
            :menu_name => new_name,
            :menu_type => 'public_web',
            :module_name => params[:namespace],
            :module_type => 'web'
          })
      end
    end
    if menu
      render :text=>"[#{{:name=>new_name,:id=>menu.id}.to_json}]"
    else
      old_menu ? render( :text=>"Izvēlne '#{new_name}' jau eksistē!", :status=>500) : render(:text=>"Kļūda", :satus=>404)
    end
  end
  
  def delete_public_menu
    menu = Admin::Menu.find_by_id(params[:id])
    if menu
      menu.destroy
      Admin::Menu.delete(menu.id)
      render :text=>"ok"
    else
      render :text=>"Kļūda", :status=>404
    end
  end

  def allowed_actions options={}
    opt=[
      ["Publiskās izvēlnes",'list_public_menus']
    ]
    options[:special_actions]=opt
    options[:return]=true
    if options[:from_controller]
      super(options)
    else
      render :text=>super(options)
    end
  end
end

