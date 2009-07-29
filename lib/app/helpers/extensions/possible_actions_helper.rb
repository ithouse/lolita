module Extensions::PossibleActionsHelper
  def can? role,access,action
    if ro_ac=Admin::AccessesRoles.find_by_role_and_access(role,access)
      ro_ac.can?(action) ? "checked='checked'" : ""
    end
  end
  
#  def change_permission controller,role,access,permission
#    "if(this.checked){
#        #{remote_function :url=>{:controller=>"/admin/#{controller}",:action=>'change_permission', :role=>role, :access=>access,:permissions=>{permission=>true}}};
#    }else{
#        #{remote_function :url=>{:controller=>"/admin/#{controller}",:action=>'change_permission', :role=>role, :access=>access, :permissions=>{permission=>false}}};
#    }"
#  end
  
  def get_all_accesses
    Admin::Access.find(:all)
  end
  def check_role(access,role)
    return "checked='checked'" if access.has_role? role
  end
  
  def check_access(role,access)
    return "checked='checked'" if role.has_access? access
  end
  def check_role_access access,role,type="checked"
    access.has_role?(role) ? "#{type}='#{type}'" : "" 
  end
  
  def related? role,access
    access.has_role?(role)
  end
  
  def change_action_relations role,access,disabled,accesses=false
    actions=['read','write','update','delete']
    id=accesses ? "accesses#{access.id}-#{role.id}" : "#{access.id}-#{role.id}"
    actions.each{|action|
      yield %(<input #{disabled ? "disabled='disabled'" : ""} id="#{id}#{action}"  class="admin-new-button" type="checkbox" #{can?(role.id,access.id,action)} />), "##{id}#{action}",action
    }
  end
  
  def change_main_relations role,access
    check_role_access(access,role.name)
#      %(onchange="
#        var actions=['read','write','update','delete'];
#        if(this.checked){
#            for(var i=0;i<actions.length;i++){
#              obj=elementById('#{prefix}#{role.id}-#{access.id}'+actions[i]);
#
#    if(obj){
#    obj.checked=true;
#    obj.disabled=false;
#    }
#            }
#            #{remote_function :url=>{:controller=>'/admin/access',:action=>'add_role', :role=>role.name, :access=>access.id}}
#        }else{
#            for(var i=0;i<actions.length;i++){
#              obj=elementById('#{prefix}#{role.id}-#{access.id}'+actions[i]);
#    if(obj){
#    obj.checked=false;
#    obj.disabled=true;
#    }
#            }
#             #{remote_function :url=>{:controller=>'/admin/access',:action=>'remove_role', :role=>role.name, :access=>access.id}}
#        }
#    ")
  end
  def check_user(role,user)
    return "checked='checked'" if role.has_user? user
  end
end