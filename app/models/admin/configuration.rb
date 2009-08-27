class Admin::Configuration < Cms::Base
  set_table_name :admin_configurations

   def self.delete_old_sessions
    begin
      sql = ActiveRecord::Base.connection();
      sql.begin_db_transaction
      sql.delete("DELETE FROM sessions WHERE updated_at<'#{72.hours.ago.strftime("%Y-%m-%d %H:%M:%S")}'")
      sql.commit_db_transaction
    rescue
      sql.rollback_db_transaction
    end
  end
  
  def find_item value
    find(:first,:conditions=>["name=?",value])
  end

  def self.system_parts user=nil
    parts=self.find(:all,:conditions=>["name LIKE ?",'system_part_url_%'],:order=>"name asc")
    parts_names=self.find(:all,:conditions=>["name LIKE ?",'system_part_name_%'],:order=>"name asc")
    0.upto(parts.size-1){|idx|
      part=parts[idx]
      simple_url=part.value.to_s.gsub(/^\//,"")
      controller,action=self.controller_and_action_from_url(simple_url)
      if user && (user.is_admin? || get_user_permission(user,controller,action))
        yield :name=>parts_names[idx].value,:controller=>controller || "",:action=>action,:namespace=>controller.split("/").first
      end
    }
  end
    
  def self.get_value_by_name name
    conf=find_by_name(name)
    if conf
      conf.value
    else
      nil
    end
  end
  class << self
    alias :get :get_value_by_name
  end

  private

  def self.get_user_permission user,controller,action
    Admin::User.authenticate_in_controller(action,controller,user,self.controller_object(controller).permissions)
  end
end
