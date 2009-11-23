class Admin::MenuItem < Cms::Manager
  set_table_name :admin_menu_items

  belongs_to :menuable, :polymorphic => true
  belongs_to :menu, :class_name=>"Admin::Menu"

  has_many :menu_items, :as=>:menuable, :dependent=>:nullify, :class_name=>"Admin::MenuItem"
  has_many    :pictures, :as=>:pictureable, :dependent=>:destroy, 
    :extend=>Extensions::ImageFileExtensions,
    :class_name=>"Media::ImageFile"
  acts_as_nested_set :scope => :menu_id #ļaujam kārtot koka struktūrās

  before_save :allow_branch_name_only_on_first_level
  translates :name,:alt_text

  def self.find_in_branch(branch_name, conditions=nil)
    root = self.find_by_branch_name(branch_name)
    if root
      self.find(:all, :conditions=>self.cms_merge_conditions(conditions, ['lft > ? and rgt < ?', root.lft, root.rgt]))
    else
      []
    end
  end

  def remove_action
    if self.menuable && self.menuable.is_a?(Admin::Action)
      self.menuable.destroy
    end
  end
  
  def update_application_menu_relations attributes={}
    action_obj=Admin::Action.find(:first,:conditions=>{:controller=>attributes[:controller],:action=>attributes[:action]})
    unless action_obj
      self.menuable = Admin::Action.create!(attributes)
      self.save!
    else
      self.change_content("Admin::Action",action_obj.id,self.is_published)
    end
  end

  def update_content_with_url url
    url_obj=Url.find_by_name(url)
    url_obj=Url.create!(:name=>url) unless url_obj
    self.change_content("Url",url_obj.id,self.is_published)
  end

  def update_content_with_object meta_url
    meta_obj=MetaData.find_by_url(meta_url)
    self.change_content(meta_obj.metaable_type,meta_obj.metaable_id,self.is_published) if meta_obj && meta_obj.metaable
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
    if self.menuable_type=="Url"
      return self.menuable.name
    elsif self.menuable_type && !self.menuable_type.include?("::StartPage")
      hsh[:controller]=self.menuable_type=="Admin::Action" ?
        self.menuable.controller.to_s  :
        "/#{self.menuable_id.to_i>0 ? self.menuable_type.to_s.underscore : ""}"

      hsh[:action]=self.menuable_type=="Admin::Action" ?
        self.menuable.action.to_s   :
        (self.menuable_id.to_i>0 ? "show" : "")

      hsh[:id]=self.menuable_type=="Admin::Action" ?
        nil  :
        (self.menuable_id.to_i>0 ? self.menuable_id : nil)
    else
      hsh[:controller]="/"
    end
    hsh
    #TODO consider upgrading to the following code
#    hsh={:locale=>I18n.locale}
#    item = self.menuable ? self : (child = get_first_child) ? child : self
#
#    if item.respond_to?(:meta_data) && item.meta_data && !(item.meta_data.url.to_s =~ /^-\d+/)
#      hsh[:controller] = "/#{item.meta_data.url}"
#    elsif item.menuable && item.menuable.respond_to?(:meta_data) && item.menuable.meta_data && !(item.menuable.meta_data.url.to_s =~ /-\d+/)
#      hsh[:controller] = "/#{item.menuable.meta_data.url}"
#    elsif item.menuable_type=="Url"
#      return item.menuable.name
#    elsif item.menuable_type && !item.menuable_type.include?("::StartPage")
#      if item.menuable_type=="Admin::Action"
#        if item.menuable && item.menuable.controller && item.menuable.action
#          hsh[:controller]=item.menuable.controller
#          hsh[:action]=item.menuable.action
#        end
#      else
#        hsh[:controller]="/#{item.menuable_id.to_i>0 ? item.menuable_type.to_s.underscore : ""}"
#        hsh[:action]=item.menuable_id.to_i>0 ? "show" : "index"
#      end
#
#      hsh[:id]=item.menuable_type=="Admin::Action" ?
#        nil  :
#        (item.menuable_id.to_i>0 ? item.menuable_id : nil)
#    else
#      hsh[:controller]="/"
#    end
#    hsh

  end

  def remove_content
    self.update_attributes!(:menuable_id=>nil, :menuable_type=>nil, :is_published=>false)
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
    self.update_attributes(:menuable_type=>new_type,:menuable_id=>new_id,:is_published=>published)
  end

  def get_url
    if self.menuable_type && self.menuable
      if self.menuable_type=="Admin::Action"
        controller=self.menuable.controller
        action=self.menuable.action
      elsif self.menuable_type!="Url"
        controller=self.menuable_type.underscore
        action="edit"
      else
        url=self.menuable.name
      end
    end
    return controller,action,url
  end

  def branch_data id=nil
    unless id
      id=self.self_and_ancestors.inject(""){|result,item|
        result<<"#{item.id}_"
      }
      id=id[0..id.size-2]
    end
    controller,action,url=self.get_url
    {
      :title=>self.name,
      :id=>id,
      :controller=>controller || "",
      :action=>action || "",
      :url=>url|| "",
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

  def allow_branch_name_only_on_first_level
    unless self.level==1
      self.branch_name=nil
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
