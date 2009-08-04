class Admin::SystemUser < Admin::User
  validates_length_of       :password, :within => 4..40, :if => :password_required?

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    user = self.find_by_login(login) # need to get the salt
    user && user.authenticated?(password)  ? user : false
  end

  def can_all? controller_name
    actions=can_what? controller_name
    actions[:read] && actions[:write] && actions[:update] && actions[:delete]
  end
  def can_anything? controller_name
    actions=can_what? controller_name
    actions[:read] || actions[:write] || actions[:update] || actions[:delete]
  end

  def can? controller_name,permission
    all_accesses(controller_name,{:permission=>permission}).empty? ? false : true
  end

  def can_delete? controller_name
    can? controller_name, :delete
  end

  def can_read? controller_name
    can? controller_name, :read
  end

  def can_what? controller_name
    permissions={:read=>false,:write=>false,:update=>false,:delete=>false}
    access=all_accesses(controller_name,:select=>"MAX(allow_read) as allow_read,MAX(allow_write) as allow_write,
        MAX(allow_update) as allow_update,MAX(allow_delete) as allow_delete"
    ).first
    if access
      permissions[:read]=access['allow_read'].to_i>0
      permissions[:write]=access['allow_write'].to_i>0
      permissions[:update]=access['allow_update'].to_i>0
      permissions[:delete]=access['allow_delete'].to_i>0
    end
    permissions
  end

  def can_write? controller_name
    can? controller_name, :write
  end

  def can_update? controller_name
    can? controller_name, :update
  end

  def can_access_action?(action,controller,options={})
    can_access,found=self.can_access_special_action?(action,controller,options)
    unless !action || found #lai iekļautu iespēju pārrakstīt pieeju noklusētajām metodēm
      case action.to_sym
      when :list,:read,:open,:index
        self.can_read?(controller)
      when :update,:edit
        self.can_update?(controller)
      when :destroy
        self.can_delete?(controller)
      when :create,:new
        self.can_write?(controller)
      end
    else
      can_access
    end
  end

  def has_access? controller_name
    return !all_accesses(controller_name).empty?
  end

  # Nosaka vai ir pieeja
  # 1. gadījumā, ja ir pieeja lomai vai lomām, tad atļauj ja lietotājam ir šī loma
  # 2. gadījums, ja ir kāda loma, kam ir pieeja dotajam modulim ar doto notikumu, dotajam pieejas līmenim
  # allow "editor"
  #   /cms/news/list = > atļauj, ja lietotājam ir loma "editor"
  # allow
  #   /cms/news/list = > atļauj, ja lietotājam ir kāda loma ar :read tiesībām Cms::News modulim
  def has_access? roles,action=nil,controller=nil,options={}
    roles=[roles] if roles.is_a?(String)
    if roles && !roles.empty?
      Admin::SystemUser.find_by_sql(["
        SELECT admin_users.id FROM admin_users
        INNER JOIN roles_users ON roles_users.user_id=admin_users.id
        WHERE roles_users.role_id IN
          (SELECT id FROM admin_roles WHERE name IN (?)) AND roles_users.user_id=?
        LIMIT 1",roles,self.id]).empty? ? false : true
    else
      return self.can_access_action?(action,controller,options)
    end
  end

  def is_real_user?
    real_user=Admin::SystemUser.find_by_login(self.login)
    real_user==self
  end

  protected

  #var norādīt kontrolierī ka ir pieejamas speciāli actioni
  # allow actions=>{
  #     :show_graphic=>:all,
  #     :remove_links=>:delete
  #     :all_documents=>"director",
  #     :delete_post=>["journalist",:delete,"editor"]
  #}
  # user.can_do_special_action_in_controller?(:delete_post,"cms/post",:actions=>{:delete_posts=>[:delete,"editor"]}
  # Norāda kāda veida pieejas tiesībai atbilst ši darbība [:delete,:write,:update,:read] un ja jekburai tad :all vai lomu(-as)
  #TODO notestēt !action_accessable(izmainīts 05.17.2009)
  def can_access_special_action?(action,controller,options={})
    action_accessable= options && options[:actions] ? options[:actions][action.to_sym] : false
    found=true
    if !action_accessable
       #iespējams piekļūta arī actioniem, ja tie ir pieejami viesiem vai publiski
      result=can_access_built_in_actions?(action,options) if options.is_a?(Hash)
      found=result
    elsif action_accessable.is_a?(Symbol)
      result=(action_accessable==:all ? self.can_all?(controller) : (action_accessable==:any ? self.can_anything?(controller) : self.can_access_simple_special_action?(action_accessable,controller)))
    elsif action_accessable.is_a?(String)
      result=self.can_access_simple_special_action?(action_accessable)
    elsif action_accessable.is_a?(Array)
      result=action_accessable.detect{|access| self.can_access_simple_special_action?(access,controller)} ? true : nil
    end
    return result,found
  end

  def can_access_built_in_actions?(action,options={})
    return self.class.action_in?(action,options[:all]) ||
    self.class.action_in?(action,options[:public]) ||
    (LOLITA_ALLOW[:system_in_public] && self.class.action_in?(action,options[:all_public]))
  end
  def can_access_simple_special_action? action_accessable,controller=nil
    if action_accessable.is_a?(Symbol) && controller && [:write,:read,:update,:delete].include?(action_accessable)
      self.send("can_#{action_accessable}?",controller)
    elsif action_accessable.is_a?(String)
      self.has_role?(action_accessable)
    end
  end
  
  def all_accesses controller_name="",opt={}
    controller_name=controller_name.to_s.gsub(/^\//,"")
    Admin::SystemUser.find_by_sql(["
      SELECT #{opt[:select] || "1"} FROM admin_users
      INNER JOIN roles_users ON roles_users.user_id=admin_users.id
      INNER JOIN accesses_roles ON roles_users.role_id=accesses_roles.role_id
      WHERE accesses_roles.access_id=(SELECT id FROM admin_accesses WHERE name=?)
      #{opt[:permission] ? "AND accesses_roles.allow_#{opt[:permission]}=1" : "" } AND admin_users.id=? LIMIT 1
        ",controller_name,self.id])
  end
end
