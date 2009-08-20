class Admin::Menu < Cms::Manager
  set_table_name :menus

  has_many :menu_items, :dependent => :destroy, :class_name=>"Admin::MenuItem"
  
  validates_presence_of :menu_name
  validates_uniqueness_of :menu_name
  
  after_create :create_root_item
    
  named_scope :app_menu, lambda{|namespace|
    {:conditions=>["module_name=? AND menu_type=?",namespace,"app"]}
  }
  named_scope :web_menu,lambda{|namespace|
    {:conditions=>["module_name=? AND menu_type=?",namespace,"web"]}
  }
  named_scope :public_menus,lambda{|namespace|
    {:conditions=>["module_name=? AND menu_type=?",namespace,"public_web"]}
  }
  named_scope :public_menu,lambda{|namespace,name|
    {:conditions=>["module_name=? AND menu_name=?",namespace,name]}
  }

  def action_item(params)
    actions=Admin::Action.find(:all,:conditions=>["controller=? AND action=?","/#{params[:controller]}",params[:action]])
    self.menu_items.find(:all,:conditions=>["menu_items.menuable_type=? AND menuable_id IN (?)","Admin::Action",actions])
  end

  def save_full_tree tree
    #eju cauri kokam pirmo reizi, un visus elementu izvietoju 1. līmenī
    #un katrs nākamais elements tiek novietots pa kreisi no iepriekšējā
    #atceros visus params[:tree] jaunā masīvā
    #@ priekš menu item esmu uzlicis, jo iekš transakcijas mainīgais nedabūja vērtību
    root=self.menu_items.first.root
    new_tree=self.create_new_tree(tree)
    #eju cauri apgrieztajam kokam
    Admin::Menu.organize_tree(new_tree)
    left_items=new_tree.transpose.first
    Admin::Menu.remove_menu_items_with_transatction((root.all_children || [])-left_items)
    root.renumber_full_tree
    self.save!
  end

  
  
  def self.accessable_modules id,options={}
    #Valdis: atsakamies no namespece ierobežojumiem veidojot menu + mums tagad ir arī lolita kur meklēt modeļus
    if menu=self.find_by_id(id)
      modules_for_display = []
      table_names=menu.humanized_modules(options[:all])
      menu.existing_modules.each{|module_hsh|
        if table_names[module_hsh[:name]]
          modules_for_display << {:display_name=>table_names[module_hsh[:name]], :system_name=>module_hsh[:name]}
        else
          modules_for_display << {:display_name=>module_hsh[:name].camelize, :system_name=>module_hsh[:name]}
        end if (!options[:all] && [Cms::Content,TableLess].include?(module_hsh[:object].constantize.superclass)) || (options[:all])
      }
      modules_for_display.sort!{|x,y| x[:display_name] <=> y[:display_name] }
      modules_for_display.each{|model|
        yield model[:display_name],model[:system_name]
      }
    end
  end

  def existing_modules
    #a=Util::System.list_directory "app/models/#{self.module_name}", :include_root=>true
    a = Util::System.get_data_models
    a
  end

  def humanized_modules all=nil,excluded=["home"], namespace=nil
    #Valdis: atsakamies no namespece ierobežojumiem veidojot menu
    table_names={}
    if namespace
      Admin::Table.in_namespace(self.module_name,all).exclude_names(excluded).by_human_name.each{|table|
        table_names[table.name]=table.human_name if table.human_name.to_s.size>0
      }
    else
      Admin::Table.exclude_names(excluded).by_human_name.each{|table|
        table_names[table.name] = "#{table.name.split('/')[0].humanize}::#{table.human_name}" if table.human_name.to_s.size>0
      }
    end
    table_names
  end
  
  def self.init_menus(namespace)
    #vienīga ko vienmēr izvedo ir cms web izvēlne
    yield self.init_application_menu(namespace),self.init_web_menu(namespace)
  end
  
  def configuration
    user=Admin::User.current_user
    {
      :current_time=>Time.now,
      :root=>self.root_item.id,
      :menu_name=>self.menu_name,
      :module_name=>self.module_name,
      :module_type=>self.module_type,
      :menu_id=>self.id,
      :menu_type=>self.menu_type,
      :accessable=>user.is_a?(Admin::SystemUser) && (user.can_all?("admin/menu") || user.is_admin?)
    }
  end
  def tree_data
    data=[]
    root_item=self.root_item
    root_parent_id=root_item.id
    items=accessable_items(root_item.all_children(root_item))
    #if items.size>0
    #  root_parent_id=items.first.parent_id
    # end
    parent_ids=[]
    #eju cauri visiem elementiem un veidoju katra elementa id
    #katrs id viennozīmīgi raksturo elementa novietojumu kokā 1_2_3
    #tas parāda visus vecāka elementus, bet pēdējais skaitlis rādā paša elementa id
    items.each{|m_item|
      #katrā gājienā izņemu no vecāku masīva pēdējo ievietoto, lai gadījumā ja gadījumā,
      #tam nav bērnu elementu tad tas vairs nav nepieciešams
      parent_id=parent_ids.pop
      #sākuma situācija, elements atrodas 1. līmenī, id saraksts tiek notīrīts
      if m_item.parent_id==root_parent_id
        id="#{m_item.id}"
        parent_ids=[]
      else
        #ja elements nav pirmajā līmenī tad izlasu no id masīva pa vienam elementus,
        #liekot vienu otram galā, tādējādi iegūstot vecāka elementa ceļu
        pid=""
        parent_ids.each{|tpid|
          pid+="#{tpid}_"
        }
        #ja elements atrodas vienā līmenī ar iepriekšējo tad tā ceļš ir
        #visu vecāku ceļš + paša id
        #tiek pārbaudīts vecāka elements vai ir vienāds ar iepriekšējā vecāka elementu
        if parent_ids.last==m_item.parent_id
          id="#{pid}#{m_item.id}"
        elsif parent_id==m_item.parent_id
          #ja nav tad nozīmē, ka elements ir iepriekšējā elementa bērns, un
          #ceļš tiek veidots no vecāku ceļa + ieriekšējais elements + paša id
          id="#{pid}#{parent_id}_#{m_item.id}"
          #iepriekšējais elements tiek ievietots atpakaļ vecāku masīvā
          parent_ids<<parent_id
        elsif parent_ids.include?(m_item.parent_id)
          t_pid=parent_ids.pop
          while t_pid!=m_item.parent_id
            t_pid=parent_ids.pop
          end
          parent_ids<<t_pid
          pid=parent_ids.inject(""){|f,el| f<<"#{el}_"}
          id="#{pid}#{m_item.id}"
        end
      end
      parent_ids<<(m_item.id)
      data<<m_item.branch_data(id)
    }
    data
  end

  def initialization_data
    {:menu=>self,:configuration=>self.configuration,:data=>self.tree_data}
  end
  
  def self.find_by_module(module_name)
    find(:first, :conditions =>"module_name = '"+module_name.to_s+"'")
  end
  
  def self.find_root_item(menu_name)
    menu=find_by_menu_name(menu_name)
    item=menu.menu_items.first
    if !item.nil?
      item.root
    else
      nil
    end
  end
  
  def root_item
    Admin::Menu.find_root_item(self.menu_name)
  end
  
  def all_menu_items
    if self.root_item
      self.root_item.all_children
    else
      []
    end
  end
  
  def all_published_items
    items = self.root_item.all_children
    items.collect!{|item| (item.is_published ? item : nil)}
    items.compact!
    items
  end

  def level1_published_items
    items = self.root_item.children
    items.collect!{|item| (item.is_published ? item : nil)}
    items.compact!
    items
  end
  
  def create_root_item
    item = Admin::MenuItem.new
    item.menu_id = self.id
    item.name = self.menu_name+'_root'
    item.save
  end

  def self.best_menu_item_for_params(params,name=nil)
    @main_public_menu||=Admin::Menu.find_by_menu_name(name || "meta_data_menu")
    if @main_public_menu
      @main_public_menu.find_by_params(params)
    end
  end
  
  def find_by_params(params)
    @current_menu_item||=Admin::MenuItem.find_for_metadata(self.id,params)
    @current_menu_item
  end

  def self.tree_translations
    {
      :edit_menu=>:"menu.tree.edit menu",
      :edit_content=>:"menu.tree.edit content",
      :expand_menu=>:"menu.tree.expand menu",
      :collapse_menu=>:"menu.tree.collapse menu",
      :refresh=>:"menu.tree.refresh",
      :add_button=>:"menu.tree.add button",
      :add_button_title=>:"menu.tree.add button title",
      :save_button=>:"menu.tree.save button",
      :save_button_title=>:"menu.save button title",
      :refresh_button_title=>:"menu.refresh button title",
      :public_menu=>:"menu.tree.public menu",
      :menu=>:"menu.tree.menu",
      :dialog_make=>:"menu.tree.dialog make",
      :dialog_cancel=>:"menu.tree.dialog cancel",
      :no_title=>:"menu.tree.no title",
      :delete_branch=>:"menu.tree.delete branch",
      :publish_branch=>:"menu.tree.publish branch",
      :remove_branch_link=>:"menu.tree.remove branch link",
      :edit_branch_content=>:"menu.tree.edit branch content",
      :edit_branch=>:"menu.tree.edit branch",
      :manage_content_tree=>:"menu.tree.manage content tree",
    }
  end
  protected

  def accessable_items items=[]
    user=Admin::User.current_user
    @existing_controllers={}
    if user && user.is_a?(Admin::SystemUser) && !user.is_admin?
      items.collect{|item|
        if item.menuable_type=="Admin::Action"
          permission=is_accessable_action?(item.menuable.controller,item.menuable.action) if item.menuable && item.menuable.controller
        else
          permission=is_accessable_action?(item.menuable_type,:show)
        end
        permission ? item : nil
      }.compact
    elsif user && user.is_a?(Admin::SystemUser) && user.is_admin?
      items #vienkārši lai paātrinātu noteikšanu
    else
      []
    end
  end

  def is_accessable_action?(controller,action)
    unless @existing_controllers.include?(controller.camelize)
      contr_object=Admin::Menu.controller_object(controller)
      @existing_controllers[controller.camelize]=contr_object
    else
      contr_object=@existing_controllers[controller.camelize]
    end
    Admin::User.authenticate_in_controller(action,controller,{:system=>Admin::User.current_user},contr_object.permissions)
  end
  
  def create_new_tree(tree)
    last,menu_item=nil,nil
    result=[]
    0.upto(tree.size-1) do |counter|
      if tree[counter].include?('new')
        tree=self.add_new_branch(tree,counter)
      end
      menu_item=Admin::MenuItem.find_by_id(tree[counter])
      result<<[last,menu_item]  if menu_item && counter % 2==1
      last=menu_item
    end
    return result
  end

  def add_new_branch tree, index
    Admin::MenuItem.transaction do
      menu_item=Admin::MenuItem.create!(:menu_id=>self.id,:name=>"Bez nosaukuma",:menuable_id=>0)
      temp_index=tree[index]
      tree.collect!{|idx| idx==temp_index ? menu_item.id.to_s : idx}
    end
    tree
  end
  
  def self.organize_tree tree
    0.upto(tree.size-1){|index|
      if menu_item=tree[index].first
        Admin::MenuItem.transaction do
          menu_item.move_to_child_of(tree[index].last)
          menu_item.parent_id=tree[index].last.id
          menu_item.save!
        end 
      end
    }
  end

  def self.remove_menu_items_with_transatction items=[]
    items.each{|item|
      Admin::MenuItem.transaction do
        item.destroy
      end
    }
  end
  
  def self.init_application_menu namespace
    menu=self.app_menu(namespace).first
    menu=self.create!(
      :menu_name=>"#{namespace}_actions",
      :menu_type=>"app",
      :module_name=>namespace,
      :module_type=>"app"
    ) unless menu
    return menu.initialization_data
  end

  def self.init_web_menu namespace
    menu=self.web_menu(namespace).first
    menu=self.create!(
      :menu_name=>"Lapas karte",
      :menu_type=>"web",
      :module_name=>namespace,
      :module_type=>"web"
    ) if !menu && namespace=="cms"
    return menu ? menu.initialization_data : nil
  end

end
