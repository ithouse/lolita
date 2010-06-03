# coding:utf-8
# Handle #Lolita fields.
module Extensions::FieldHelper
  include Extensions::SingleFieldHelper

  # :roles=>{:include=>["editor"]}
  # :roles=>{:exclude=>{:edit=>["editor"]}
  # Determine wheteher or not field is editable by current user see Admin::User#current_user.
  # Needed information are provided via configuration in controllers.
  # All fields are editable by administrator unless editing is blocked for action.
  # ====Example
  #     User < Managed
  #      def config
  #       {
  #         :fields=>[
  #           {:type=>:text,:field=>:name},
  #           {:type=>:text, :field=>:login, :actions=>[:new]},
  #           {:type=>:text, :field=>:card_number, :roles=>{:exclude=>{:new=>[:user_manager]}}}
  #         ]
  #       }
  #      end
  #     end
  #     # In helpers or views
  #     params[:action] #=> :edit
  #     Admin::User.current_user.has_role?(:admin) #=>true
  #     can_edit_field?(:login) #=>true
  #     Admin can edit all fiels, and user_manager too.
  #     
  #     params[:action] #=>:new
  #     Nobody can edit :login field and user manager can't edit :card_number field.
  def can_edit_field? field
    user=Admin::User.current_user
    allow_action=((!field[:actions])||(field[:actions] && field[:actions].include?(params[:action].to_sym)))
    if field[:roles]
      include_roles=if field[:roles][:include].is_a?(Hash)
        field[:roles][:include][params[:action].to_sym]
      else
        field[:roles][:include]
      end
      has_role=include_roles ? include_roles.detect{|role| user.has_role?(role)} : true
      exclude_roles=if field[:roles][:exclude].is_a?(Hash)
        (field[:roles][:exclude][params[:action].to_sym] || [])
      else
        (field[:roles][:exclude] || [])
      end
      no_role=exclude_roles.detect{|role| user.has_role?(role)}
    end
    allow_role=(user.is_admin? && (exclude_roles && !exclude_roles.detect{|role| role==Admin::Role.admin}) || !exclude_roles) || !field[:roles] || (field[:roles] && has_role && !no_role)
    allow_action && allow_role
  end

  # Create title for +object+ attribute from Array +field+.
  # Elements of Array can by Symbol or String.
  # When Symbols are passed then these elements are replaced with +object+ attribute with same name.
  # String aren't replaced unless it starts with <b>:</b>. Then anyting from start till first character that isn't
  # number, letter or _ is replaced like it was Symbol and anything left in string will be evaluted.
  # ====Example
  #     @object #=> {:id=>1, :name=>"test"}
  #     field_to_string_simple(["name_",:id],@object) #=> name_1
  #     field_to_string_simple([":name.gsub('t','')"]) #=> es
  def field_to_string_simple field,object
    result=""
    field.each{|value|
      if value.is_a?(Symbol)
        result+=object.send(value.to_s).to_s
      elsif value.is_a?(String) && value.match(/:\w+/)
        new_constr=value.gsub(/:\w+/){|field_name|
          "object.send('#{field_name.gsub(":","")}')"
        }
        result+=eval(new_constr).to_s
      else
        result+=value
      end
    }
    result
  end

  # Create array from +data+ and +titles+ and return it as 2-dimensional Array.
  # For +titles+ detail see #field_to_string_simple.
  # ====Example
  #     cms_simple_options_for_select(User.find(:all),:login)
  #     #=> [["admin",1]]
  #     cms_simple_options_for_select(User.find(:all),[:login,"_",:id]
  #     #=> [["admin_1",1]]
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

  # Return tab Hash. +Tab+ can be Hash or Integer.
  # When Hash received than return itself otherwise try to find tab with given index in configuration.
  def get_tab(tab)
    tab.is_a?(Hash) ? tab : (@config[:tabs] ? @config[:tabs][tab] : nil)
  end

  # Create array of field and necessary information about it for lolita form observer javascript.
  def create_fields_for_js(fields)
    result=[]
    fields.each{|f_arr|
      f_arr[1].each{|f_obj|
        result<<[f_arr[0],{:field=>f_obj[:field],:type=>f_obj[:type],:simple=>f_obj[:simple]}]
      }
    }
    result
  end

  # Return all fields configuration for tab (see #get_tab) or empty Array.
  def fields_for_tab(tab)
    tab=get_tab(tab)
    if tab && tab[:fields]
      (tab[:fields]==:default ? @config[:fields] : tab[:fields])
    else
      []
    end
  end

  # Return all field for single tab or merge all tabs fields or all tabs with object name and field.
  # Excepts +tab+ as Integer or Hash (see #get_tab) and +options+
  # * <tt>:with_object</tt> - return array with object name as first and field as last of elements.
  # * <tt>:in_form</tt> - whether or not tab need to be in form.
  def tabs_fields tab=nil,options={}
    if tab.nil?
      if options[:with_object]
        @config[:tabs].inject([]){|result,tab|
          result<<[tab[:object] || (tab[:type] == :translate ? :translation : :object),tabs_fields(tab,options)]
        }
      else
        @config[:tabs].inject([]){|result,tab|
          result=result+tabs_fields(tab,options)
        }
      end
    else
      tab=get_tab(tab)
      if tab && tab[:fields] && (!options[:in_form] || tab[:in_form]==options[:in_form])
        ((tab && tab[:fields]==:default)) ? @config[:fields] : tab[:fields]
      else
        []
      end
    end
  end

  # Determine if exist +field+ with given type in all tabs or in specified +tab+.
  # Any field with option :simple set to true is ignored.
  # ====Example
  #     is_field(:textarea,1) #=> false
  def is_field?(field_type,tab=nil)
    tabs_fields(tab).each{|value|
      if value[:type] && value[:type].to_sym==field_type.to_sym && !value[:simple]
        return true
      end
    }
    return false
  end
 
  # Render field with given +type+ if Lolita support that kind of field type.
  # Options also can be specified, common options are described here for detailed information about
  # field options see #Extensions::SingleFieldHelper.
  # Common options:
  # * <tt>:field</tt> - field name
  # * <tt>:html</tt> - HTML attributes, not all types support it
  # * <tt>:object</tt> - Object name, by default :object, is used to get value of field from instance variable with same name.
  # Accepted field types:
  # * autocomplete
  # * custom
  # * label
  # * content_tree
  # * hidden
  # * text
  # * password
  # * number
  # * date
  # * datetime
  # * checkbox
  # * textarea
  # * select
  # * checkbox_group
  # * multi_select
  # * multi_input
  def field_render (type,options={})
    options[:html]||={}
    object=options[:object] ? options[:object] : :object
    case type.to_sym
    when :autocomplete
      autocomplete_field(object,options[:field],options[:url],options.delete_if{|key, value| key == :url } ).html_safe
    when :content_tree
      cms_content_tree_field(object,options).html_safe
    when :custom
      cms_custom_field(object,options).html_safe
    when :label
      cms_label_field(object,options).html_safe
    when :hidden
      cms_hidden_field(object,options).html_safe
    when :text
      options[:html][:class]||="txt"
      cms_text_field(object,options).html_safe
    when :password
      password_field(object,options[:field],options[:html]).html_safe
    when :number
      options.delete(:field)
      number_field(object, options[:field], options[:html]).html_safe
    when :date
      date_select object, options[:field], options[:config],options[:html]
    when :datetime
      datetime_select(object,options[:field],options[:config],options[:html]).html_safe
    when :checkbox
      options[:html][:class]||="txt"
      check_box(object,options[:field],options[:html]).html_safe
    when :textarea
      cms_textarea(object,options).html_safe
    when :select
      cms_select_field(object,options).html_safe
    when :checkboxgroup
      cms_checkboxgroup_field(object,options).html_safe
    when :multi_select
      cms_multi_select_field(options).html_safe
    when :multi_input
      cms_multi_input_field(options).html_safe
    else
      ""
    end
  end
end
