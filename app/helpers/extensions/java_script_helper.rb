module Extensions::JavaScriptHelper

  #TODO noņemt lai stils tiek pievienots
  def autocomplete_field object_name, method, url={},options={}
    url||={:action=>params[:action],:controller=>params[:controller]}
    options[:html]||={}
    if options[:add_new]
      options[:html][:style]||=""
      options[:html][:style]+="width:505px;"
    end
    #random_index=rand(10000)
    #NOŅĒMU random index, jo nav jēga
    dialog=%^
     autocomplete_dialog_#{object_name}_#{method}=new CmsDialog("#{object_name}_#{method}_autocomplete_dialog",
        {width:"300px"},{
          success:"add_new_element_to_autocomplete('#autocomplete_#{object_name}_#{method}',request.responseText)"
        }
    )^
    
    if options[:add_new]
      options[:html][:id]="autocomplete_#{object_name}_#{method}"
      result=%!<div class="autocomplete-container" style="#{options[:html][:style]}">
        #{text_field object_name,method,options[:html].delete_if{|key,value| key==:style}}#{options[:add_new] ? image_tag("/lolita/images/icons/add.png",:alt=>"+",:onclick=>"autocomplete_dialog_#{object_name}_#{method}.dialog.show()",:style=>"cursor:pointer;position:absolute;left:510px;top:3px") : ""}
        <div id="autocomplete_container_#{object_name}_#{method}"></div>
      </div>!
      result+=javascript_tag(%!
      new ITH.Editor.AutoComplete("autocomplete_#{object_name}_#{method}","autocomplete_container_#{object_name}_#{method}","#{url_for(url)}")
      #{dialog}!)
    end
    result
  end
  
  def change_advanced_filter options={:url=>{:action=>"list"}}
    url=url_for({:escape=>false}.merge(options[:url]))
    %!change_advanced_filter(this.value,'#{url}')!
  end
  
  def yui_draggable_element id,options={}
    default={
      :group=>"default",
      :update=>{:success=>"success",:failure=>"failure"},
      :url=>{}
    }
    options=default.merge(options)
    url=url_for({:escape=>false}.merge(options[:url]))
    options[:url]=url
    javascript_tag(%(try{new DraggableElement(#{id.to_json},#{options.to_json})}catch(err){}))
  end
  
  def yui_drop_receiving_element id, group=nil
    javascript_tag( %(try{new DropReceivingElement(#{id.to_json},#{group.to_json})}catch(err){}))
  end
  
  def get_actions_js container,menu_item_id,public=false
    %!
      simple_yui_request(this,{
        url:'/admin/menu_item/controller_actions',
        container:'#{container}',
        method:'POST',
        params:{
        authenticity_token: '#{CGI::escape(form_authenticity_token)}',
        public:#{public ? "true" : "false"},
        menu_item_id:#{menu_item_id},
        controller_name:this.value
        }
      })
    !
  end
 
  def number_field(object, method, options={})
    if options[:decimal]
      onchange="if (this.value!=parseFloat(this.value)){this.value=isNaN(parseFloat(this.value))?'':parseFloat(this.value)}"
    else
      onchange="if (this.value!=parseInt(this.value)){this.value=isNaN(parseInt(this.value))?'':parseInt(this.value)}"
    end
    result = ActionView::Helpers::InstanceTag.new(object, method, self).to_input_field_tag("text", options.merge(:onkeyup=>onchange))
  end
 
  def date_field(object,method,options={})
    onchange="res=checkDate(this.value,event);if (res[1]){this.value=res[1];return false;}else{return res[0]} "
    onkeyup=""
    result = ActionView::Helpers::InstanceTag.new(object, method, self).to_input_field_tag("text", options.merge(:onkeydown=>onchange,:onkeyup=>onkeyup,:maxlength=>10))
  end
 
  def auto_uploadable(action,form_id,element_id,event="",target="",config={})
    if (action && form_id && element_id)
      javascript_tag(auto_uploadable_js(action,form_id,element_id,event,target,config))
    end
  end
  
  def auto_uploadable_js(action,form_id,element_id,event="",target="",overwrite=false)
    %!new AutoUploadForm(#{action.to_json},#{form_id.to_json},#{element_id.to_json},#{event.to_json},#{target.to_json},#{overwrite.to_json});!
  end
end