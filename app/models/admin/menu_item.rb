class Admin::MenuItem < Cms::Manager
  set_table_name :menu_items

  belongs_to :menuable, :polymorphic => true
  belongs_to :menu, :class_name=>"Admin::Menu"

  has_many :menu_items, :as=>:menuable, :dependent=>:nullify, :class_name=>"Admin::MenuItem"
  #has_many :start_pages, :dependent=>:nullify, :class_name=>"Cms::StartPage" #sākumlapai var būt vairākas sadaļas no satura
  has_many    :pictures, :as=>:pictureable, :dependent=>:destroy, :extend=>Extensions::PictureExtensions
  acts_as_nested_set :scope => :menu_id #ļaujam kārtot koka struktūrās
  
  # before_save :set_stamps
  before_destroy :remove_links_and_references
  translates :name,:alt_text

  def remove_action
    if self.menuable && self.menuable.is_a?(Admin::Action)
      self.menuable.destroy
    end
  end
  def update_or_create_public_item public_item,name,position,parent_id
    public_item=self.create_public_item(name,parent_id,position) unless public_item
    public_item.name=="Bez nosaukuma" ? name : nil
    public_item
  end

  def update_application_menu_relations attributes={}
    if !self.menuable || (self.menuable && !self.menuable.is_a?(Admin::Action))
      self.menuable = Admin::Action.create!(attributes)
      self.save!
    else
      self.menuable.update_attributes!(attributes)
    end
  end

  def update_menu_with_url url
    self.update_attributes!(:menuable_type=>"Admin::MenuItem",:menuable_id=>0,:url=>url)
  end
  def update_web_menu_relations parent_type
    menuable_id=(self.menuable_id.to_i<1 || (parent_type && parent_type!=self.menuable_type)) ? 0 : self.menuable_id
    self.change_content(parent_type,menuable_id,menuable_id>0)
  end

  def update_public_web_menu_relations item_id
    source=Admin::MenuItem.find_by_id(item_id)
    if source
      if source.menuable
        self.update_attributes!(
          :menuable_type=>source.menuable_type,
          :menuable_id=>source.menuable_id,
          :is_published=>source.is_published
        )
      else
        self.update_attributes!(
          :menuable_type=>"Admin::MenuItem",
          :menuable_id=>item_id,
          :is_published=>source.is_published
        )
      end
    end if source
  end
  
  def self.get_deepest_item items=[]
    menu_item = items[0]
    menu_item =items.detect{ |item|
      item if item.level > menu_item.level
    } || menu_item if items.size > 1
    menu_item
  end
  
  def link
    hsh={}
    if self.menuable_type && !self.menuable_type.include?("::StartPage")
      hsh[:controller]=self.menuable_type=="Admin::Action" ? self.menuable.controller.to_s : "/#{self.menuable_id.to_i>0 ? self.menuable_type.to_s.underscore : ""}"
      hsh[:action]=self.menuable_type=="Admin::Action" ? self.menuable.action.to_s :  (self.menuable_id.to_i>0 ? "show" : "")
      hsh[:id]=self.menuable_type=="Admin::Action" ? nil : (self.menuable_id.to_i>0 ? self.menuable_id : nil)
    else
      hsh[:controller]="/"
    end
    hsh
  end

  def remove_content tables=nil,menuable=nil
    public_menus=tables || Admin::Menu.public_menus(self.menu.module_name)
    ids=[]
    unless menuable
      Admin::MenuItem.find(:all,:conditions=>[
          "menu_id IN (?) AND menuable_type=? AND menuable_id=?",public_menus,self.menuable_type,self.menuable_id
        ]).each{|item|ids+=item.remove_content(public_menus,self)}
    end
    ids<<self.id
    unless menuable
      self.update_attributes!(:menuable_id=>nil, :menuable_type=>nil, :is_published=>false)
    else
      self.update_attributes!(:menuable_id=>menuable.id, :menuable_type=>menuable.class.to_s,:is_published=>false)
    end
    ids
  end

  # Pievieno publiskās izvēlnes zaram saturu no satura izvēlnes zara,
  # ja saturs nav, t.i., <code>id=0</code>, tad tiek saglabāta reference uz atbilstošo
  # satura koka zaru. Visiem zariem šajā publiskajā izvēlnē, kam ir šāda pati saite (uz objektu, vai zara reference)
  # tiek tā <b>noņemta</b>, lai saglabātu loģiku kokā.<br/>
  # Tiek atgriezti zari, kam ir noņemts saturs!
  def add_public_content content_item,name=nil
    deleted_content_items=[]
    if content_item.menuable_id.to_i==0
      id=content_item.id
      type="Admin::MenuItem"
    else
      id=content_item.menuable_id
      type=content_item.menuable_type
    end
    published=content_item.is_published
    if self.menu.menu_type=="public_web"
      Admin::MenuItem.find(:all,:conditions=>["menu_id=? AND menuable_type=? AND menuable_id=?",self.menu_id,type,id]).each do |item|
        item.remove_content #noņemu visiem saturu, kas vienāds ar šo šajā menu
        deleted_content_items<<item unless self==item
      end
      self.update_attributes(:menuable_type=>type,:menuable_id=>id,:is_published=>published,:name=>name ? name : self.name) # pievienoju šim elementam šo saturu
    end
    deleted_content_items
  end

  # Mainoties <i>Satura koka</i> piesaistītajam objektam, tiek mainīti piesaistītie objekti<br/>
  # visiem šīs vārdkopas publisko izvēļnu zariem ar šadu pašu piesaisti vai referenci uz šo zaru<br/>
  # Gadījums, kad ir bijusi sasaiste ar kādu objektu un tā tiek mainīta<br/>
  #   content_item{:id=>1,:menuable_type=>"Cms::News",:menuable_id=>1,:published=>0}.change_content("Cms::TextPage",1,true)
  #   Atbilstošajiem publisko izvēļņu zariem ar <code>menuable_type</code> <tt>"Cms::News"</tt> un
  #   <code>menuable_id</code> <tt>1</tt> tiek nomainīti uz norādīto tipu ar norādīto id.<br/>
  # Gadījums, kad sasaiste nav bijusi un tā tiek izveidota <br/>
  #   <code>content_item{:id=>1, :menuable_type=>"Cms::News", :menuable_id=>0,:published=>0}.change_content("Cms::News",1,true)</code>
  #   Atbilstošo publisko izvēļņu zariem, kam bijusi reference uz šo <tt>Satura izvēlnes</tt> zaru
  #   tiek izveidota sasaiste uz <code>Cms::News</code> klases objektu ar id 1
  #
  def change_content new_type,new_id,published=nil
    public_menus=Admin::Menu.public_menus(self.menu.module_name)
    if new_id.to_i>0
      menu_items=Admin::MenuItem.find(:all,:conditions=>[
          "menu_id in (?) AND ((menuable_type=? AND menuable_id=?) OR (menuable_type=? AND menuable_id=?))",
          public_menus,self.menuable_type,self.menuable_id,"Admin::MenuItem",self.id
        ])
      menu_items.each{|item|
        item.update_attributes(:menuable_type=>new_type,:menuable_id=>new_id,:is_published=>published)
      }
    end
    self.update_attributes(:menuable_type=>new_type,:menuable_id=>new_id,:is_published=>published)
  end
  
  def branch_data id=nil
    unless id
      id=self.self_and_ancestors.inject(""){|result,item|
        result<<"#{item.id}_"
      }
      id=id[0..id.size-2]
    end
    controller=self.menuable_type ?
      (self.menuable_type=="Admin::Action" && self.menuable ?
        self.menuable.controller :
        (self.menuable_type=="Admin::MenuItem" && self.menuable ?
          self.menuable.menuable_type.underscore :
          self.menuable_type.underscore)
    ):""
    action=self.menuable_type=="Admin::Action" && self.menuable ? self.menuable.action :
      (self.menuable_type=="Admin::MenuItem" && self.menuable ? "create" :
        (self.menuable_id.to_i>0 ? "update" : (self.menuable_type.to_s.size>0 ? "create" : ""))
    )
    {
      :title=>self.name,
      :id=>id,
      :controller=>controller,
      :action=>action,
      :menuable_type=>self.menuable_type,
      :menuable_id=>self.menuable_id,
      :published=>self.is_published,
      :menu_type=>self.menu.menu_type,
      :module_name=>self.menu.module_name,
      :module_type=>self.menu.module_type
    }
  end

  def self.updated_items old_time, menu_id
    self.find_newer_than(old_time, menu_id).collect{|item|
      [item.id,item.id,item.branch_data]
    }
  end
  
  def self.find_newer_than time,menu_id
    find(:all,:conditions=>["updated_at>? AND menu_id=?",time,menu_id])
  end

  def self.find_by_name_and_menu name,menu
    menu=Admin::Menu.find_by_menu_name(menu)
    menu.menu_items.find_by_name(name) if menu
  end
  
  def self.find_menu_items(menu_name)
    if !menu_name.nil?
      root = Admin::Menu.find_root_item(menu_name)
      if root
        root.all_children
      end
    else
      []
    end
  end
  
  def all_published_children
    items = self.all_children
    items.collect!{|item| (item.is_published ? item : nil)}
    items.compact!
    items
  end


  #TODO var rasties gļuki ja kāds piešķir vērtību is_published un nesaglabā sākotnējo elementu t.i. self
  def is_published=(is_published)
    if self.menu && self.menu.menu_type=='web' # doma tātad ka published visiem līdzīgajiem itemiem mainās tikai tad kad mainās content
      #bet ja mainās citiem menu tad nemainās content un citiem menu
      if !(self.menuable_type.nil? || self.menuable_id.nil?)
        items = Admin::MenuItem.find(:all, :conditions=>["menuable_type=? AND menuable_id=? AND menu_items.id!=?",self.menuable_type,self.menuable_id,self.id])
        for item in items
          item.is_published_self_only(is_published)
          item.save
        end
      end
      is_published_self_only(is_published)
    else
      is_published_self_only(is_published)
    end
  end
  
  def is_published_self_only(is_published)
    write_attribute(:is_published, is_published)
  end

  def self.find_for_metadata(menu_id,params)
    menu_items=self.find_by_menu_and_params(menu_id,params)
    unless menu_items.empty?
      MetaData.find(:first,:conditions=>["metaable_type=? AND metaable_id IN (?)","Admin::MenuItem",menu_items.collect{|m| m.id}], :order=>"title desc")
      #Admin::MenuItem.find_by_id(meta_data.metaable_id)
    end
  end

  def self.find_by_menu_and_params(menu_id,params)
    if params[:id]
      menu_items=self.find(:all,:conditions=>["menu_id=? AND menuable_type=? AND menuable_id=?",menu_id,params[:controller].camelize,params[:id]])
    end
    if !menu_items || menu_items.empty?
      actions=Admin::Action.find(:all,:conditions=>["controller=? AND action=?","/#{params[:controller]}", params[:action]]).collect{|a| a.id}
      menu_items=self.find(:all,:conditions=>["menu_id=? AND menuable_type=? AND menuable_id IN (?)",menu_id,"Admin::Action",actions])
    end
    menu_items
  end

  def action
    if self.menuable_type=="Admin::Action"
      self.menuable.action
    end
  end

  def controller
    if self.menuable_type=="Admin::Action"
      self.menuable.controller
    end
  end
  private

  def create_public_item name,parent_id,position
    public_item=Admin::MenuItem.create!(
      :menu_id=>self.menu_id,
      :name=>name,
      :menuable_id=>0,
      :parent_id=>parent_id
    )
    case position
    when "child"
      public_item.move_to_child_of(self)
    when "prev_sibling"
      public_item.move_to_left_of(self)
    when "next_sibling"
      public_item.move_to_right_of(self)
    end
    public_item.root.renumber_full_tree
    public_item
  end
  # Ja tiek izdzēsts satura koka zars, tad visiem tam piesaistītajiem zariem un zariem ar
  # atsauci uz šo zaru publiskajās izvēlnēs tiek ņoņemts saturs vai atsauce, lai saglabātu
  # integritāti, un vienmēr publiskās izvēlnes zarams būtu sasaiste ar reālu zaru satura kokā
  def remove_links_and_references
    if self.menu.menu_type=="web"
      Admin::MenuItem.find(:all,:conditions=>[
          "menu_id IN (?) AND ((menuable_type=? AND menuable_id=?) OR (menuable_type=? AND menuable_id=?))",
          Admin::Menu.public_menus(self.menu.module_name),self.menuable_type,self.menuable_id,"Admin::MenuItem",self.id]).each{|item|
        item.remove_content
      }

    end
  end

  def set_stamps
    if @changed_attributes.size>0
      self.updated_at=Time.now#now.strftime("%Y-%m-%d %H:%M:%S")
      self.created_at=Time.now unless self.created_at
    end
    # a=1
  end
 
  def all_accesses user_id
    accesses=[]
    user=Admin::User.find(user_id)
    user.roles.each{|role|
      role.accesses.each{|access|
        unless accesses.include?(access)
          accesses<<access.name
        end
      }
    }
    accesses
  end
end
