# coding: utf-8
# Helper module for administrative controllers, that operates with users, roles and
# accesses.
module Extensions::AdministrationHelper

  # Return 20 user object records if _user_obj_ is given or all roles.
  # Mostly there are no more than 20 roles in system.
  def get_roles_or_users user_obj
    unless user_obj
      Admin::User.lolita_paginate(:per_page=>20,:page=>params[:page],:conditions=>params[:type] ? ["type=?",params[:type]] : nil)
    else 
      Admin::Role.find(:all,:conditions=>!user_obj.is_a?(Admin::SystemUser) ? ["name!=?",Admin::Role::ADMIN] : nil) 
    end 
  end

  # Return url for user objects or roles if user is given as _is_user_.
  # If user is system user that path goes to Admin::UserController otherwise
  # if exists +controller+ for user model, than links to that controller.
  # ====Example
  #     get_roles_or_user_url(my_user_obj,false) #=> if MyUserController exists, than
  #                                                  link would be /my_users/list/some_id
  def get_role_or_user_url(object,is_user)
    if is_user
      list_role_path(object.id)
    else
      if object.type=="Admin::SystemUser"
        list_user_path(object.id)
      else
        contr="#{object.type}Controller".constantize rescue nil
        if contr
          url_for(:controller=>object.type.underscore,:action=>:list,:id=>object.id)
        else
          list_user_path(object.id)
        end
      end
    end
  end

  # Specific method for roles-accesses relation list where are many checkboxes that
  # changing need to do request and store information.
  def change_action_relations role,access
    disabled=!access.has_role?(role)
    actions=['read','write','update','delete']
    id="#{access.id}-#{role.id}"
    permissions=role.can_what_with_access?(access)
    actions.each{|action|
      yield %^
              <input #{disabled ? "disabled='disabled'" : ""}
              id="#{id}#{action}"
              class="admin-new-button"
              type="checkbox" #{permissions[action.to_sym] ? "checked='checked'" : ''}
              onchange="Administration.change_access_permissions(this,'#{change_role_access_path(:role_id=>role.id,:id=>access.id)}','#{action}')"
            />^
    }
  end

  # Simple method that returns for +input+ field if that field need to be checked,
  # depending on role and access relationship.
  def change_main_relations role,access
    access.has_role?(role) ? "checked='checked'" : ""
  end
end