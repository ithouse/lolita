class Admin::MenuItemController < Managed
  allow

  def controller_actions
    if params[:controller_name]
      begin
        controller=params[:controller_name][1,999] if params[:controller_name][0,1] == "/"
        controller="#{controller}_controller".camelize.constantize
        current_item=Admin::MenuItem.find_by_id(params[:menu_item_id])
        current_action=current_item.menuable.action if current_item && current_item.menuable.is_a?(Admin::Action)
        allowed_actions=params[:public].to_b ? controller.public_actions : controller.default_actions+controller.system_actions
        allowed_actions.collect!{|action|
          name=action.first.is_a?(Symbol) ? t(action.first) : action.first
          name=name.to_s.size>0 ? name : nil
          [name || action.last.to_s.humanize, action.last]
        }
      rescue Exception => e #ne visi kontrolieri eksistē
        allowed_actions=[t(:"notice.not_followed"),""]
      end
    end
    render :partial=>"options", :layout=>false, :locals=>{:options=>allowed_actions || [],:current=>current_action}
  end

  def get_meta_url
    result=MetaData.url_match params[:query],["metaable_type!=?","Admin::MenuItem"]
    render :text=>result.uniq.join("\t")
  end
  
  def update
    @menu_data=my_params[:object][:menu] if my_params[:object]
    my_params[:object].delete(:menu) if my_params[:object]
    super
    @object=Admin::MenuItem.find_by_id(@object.id) if @object
    handle_menu_item_relation @menu_data
    cancel
  end


  def create
    if request.post?
      if my_params[:object]
        @menu_data=my_params[:object][:menu]
        my_params[:object][:name]=my_params[:object][:name].size>0 ? my_params[:object][:name] : t(:"menu item.untitled")
        my_params[:object][:menu_id]=my_params[:menu_id]
      end
      my_params[:object].delete(:menu) if my_params[:object]
      super

      if my_params[:parent_element_id].include?("new")
        my_params[:parent_element_id]=Admin::Menu.find(my_params[:menu_id]).menu_items.first.root.id
        my_params[:move_to_id]=false
      end
      if my_params[:move_to_id].to_b
        @object.move_to_right_of(my_params[:parent_element_id])
      else
        @object.move_to_child_of(my_params[:parent_element_id])
      end
      @object.save!
      handle_menu_item_relation @menu_data
      cancel
    end
  end

  def cancel
    if @object
      text=%(ITH.MenuTree.Functions.refreshTree("#{@old_id}",#{@object.id},#{@object.branch_data.to_json}); )
    else
      menu=Admin::Menu.find_by_id(params[:menu_id])
      text="ITH.MenuTree.Functions.refreshTree(0,0,#{{:menu_type=>menu ? menu.menu_type : false}.to_json});"
    end
    render :text=>%(<script type="text/javascript">#{text}</script>)
  end
  private

  def config
    {
      :do_not_redirect=>true,
      :redirect_to=>"cancel",
      :tabs=>[
        {:fields=>:default,:type=>:content, :in_form=>true,:opened=>true},
        {:type=>:metadata, :in_form=>true},
        {:type=>:translate, :fields=>:default, :in_form => true},
        {:main_image=>true,:type=>:multimedia,:media=>:image_file,:single=>false}
      ],
      :fields=>[
        {:type=>:text,:field=>:name,:translate=>true,:html=>{:maxlength=>255}},
        {:type=>:text,:field=>:alt_text,:translate=>true,:html=>{:maxlength=>255}},
        {:type=>:text, :field=>:branch_name,:html=>{:maxlength=>255}},
        {:type=>:custom,:field=>"menu",:function=>'get_menu_editors',:args=>[params[:menu_id]]}
      ]
    }
  end
  def handle_menu_item_relation menu_data={}
    Admin::MenuItem.transaction do
      menu_data||={}
      menu_data[:table]=menu_data[:table].to_s.size>0 ? menu_data[:table] : nil
      @old_id=my_params[:old_menu_item_id]
      case @object.menu.menu_type
      when 'app'
        @object.update_application_menu_relations(:controller=>menu_data[:table],:action=>menu_data[:action]) if(menu_data[:action].to_i!=-1)
      when 'web'
        if params[:relation_type].to_i==0
          @object.update_application_menu_relations(:controller=>menu_data[:table],:action=>menu_data[:action]) if(menu_data[:action].to_i!=-1)
        elsif params[:relation_type].to_i==1
          @object.update_content_with_url(menu_data[:url])
        elsif params[:relation_type].to_i==2
          @object.update_content_with_object(menu_data[:meta_url])
        end
      end
    end
  end
end
