# coding:utf-8
module Extensions::SingleFieldHelper

  # Create counter for textarea see #cms_statusbar.
  # Accepted options:
  # * <tt>:title</tt> - Title for counter, if %d be found in text, then it will be replaces with :maxlength
  # Accpted html options:
  # * <tt>:maxlength</tt> - Maximum length that can be displayed in :title it include %d
  # ====Example
  #  create_counter("object_text",{:title=>"Symbols left %d"},{:maxlength=>55}) #=>
  #  <span id='object_text_counter'>Symbols left 55</span>
  #  <script type="text/javascript">
  #   new ITH.Editor.TextareaCounter('#object_text')
  #  </script>
  def create_counter id, options={},html={}
    counter="#{options[:title]%html[:maxlength]}"
    "<span id='#{id}_counter'>#{counter}</span>"+javascript_tag("new ITH.Editor.TextareaCounter('##{id}')")
  end

  # Create statusbar for #cms_textarea and puts counter in it if counter options specified.
  # Create div tag for statusbar.
  # Accepted options:
  # * <tt>:counter</tt> - Hash that be passed to #create_counter as options.
  # Accpted all options:
  # * <tt>:html</tt> - Hash with html options that will be passed to #create_counter.
  # ====Example
  #   create_statusbar('object_text',{:counter=>{:title=>"Maximum: %d}},{:maxlength=>55}") #=>
  #   <div id="object_text_statusbar"></div>
  def create_statusbar id, options={},all_options={}
    bar=""
    if options[:counter]
      bar<<create_counter(id,options[:counter],all_options[:html])
    end
    %(<div id="#{id}_statusbar">#{bar}</div>)
  end

  # Create text area field and statusbar if specified.
  # Accpts _object_ name and options.
  # Accpeted options:
  # * <tt>:html</tt> - HTML options, other #text_area html options can be given as well:
  #   * <tt>:cols</tt> - Column count for textfield.
  #   * <tt>:class</tt> - Class name, that is combinated with specific *Lolita* class name unless <tt>:simple</tt> is set to true.
  # * <tt>:simple</tt> - Determinate that textfield is used without *TinyMCE*.
  # * <tt>:statusbar</tt> - Create status bar specified. See #create_statusbar.
  # * <tt>:field</tt> - Field name.
  #
  # ====Example
  #   cms_textarea "blog", :field=>"text", :cols=>20
  #   cms_textarea "blog", :field=>"text", :cols=>20, :statusbar=>{:counter=>{:title=>"Maximum: %d}}, :maxlength=>55
  def cms_textarea object,options
    options[:html][:cols]||=50
    options[:html][:class]||="textarea"
    options[:html][:class]="#{options[:html][:class]} textarea-#{object}" unless options[:simple]
    if options[:simple] && options[:statusbar]
      status_bar=create_statusbar("#{object}_#{options[:field]}",options[:statusbar],options)
    end
    "#{text_area object, options[:field], options[:html]}#{status_bar} <br/>"
  end
  
  def cms_content_tree_field object,options # :nodoc: 
    if menu=Admin::Menu.web_menu("Admin").first #Valdis: atejam no namespecotā menu - if menu=Admin::Menu.web_menu(params[:controller].split("/").first).first
      id=params[:action]=='update' ? instance_variable_get("@#{object}").id : 0
      menu_items=menu.all_menu_items
      mi=[[t(:"fields.not_related"),0]]
      menu_items.each{|item|
        mi<<["#{'--'*(item.level-1)}#{item.name}",item.id]
      }
      current_menu=Admin::MenuItem.find(:first,:conditions=>["menuable_type=? and menuable_id=? and menu_id=?",@config[:object_name].camelize,id>0 ? id : -1,menu.id])
      current_menu_id=params[:menu_item_id] ? params[:menu_item_id].to_i : (current_menu ? current_menu.id : 0)
      content_tag("table",content_tag("tr",
          content_tag("td",
            content_tag('input',"",:type=>"hidden",:value=>menu.id,:name=>"object[menu_record][menu_id]")+
              select_tag("object[menu_record][branch]",options_for_select(mi,current_menu_id),:style=>"width:300px;")
          )+
            content_tag("td",
            image_tag("/lolita/images/cms/arrow_blue_s.gif",:alt=>"",:onclick=>"toggle_tree_arrows(this)")
          )+
            content_tag("td",
            content_tag("input","",:id=>"object_menu_record_new",:name=>"object[menu_record][new]",:class=>"txt",:style=>"width:211px;")+
              content_tag('input',"",:value=>"s",:type=>"hidden",:id=>"object_menu_record_dir",:name=>"object[menu_record][dir]")
          )
        ))
    end
  end

  # Create custom field for special use. Method must be accessable from this helper.
  # Arguments may be passed to that method.
  # Arguments:
  # * <tt>object</tt> - Object name, instance variable with this name must exist.
  # * <tt>options</tt> - Options need to be passed too:
  #   * <tt>:function</tt> - Function that be called with given instance variable id or 0, field and other arguments.
  #   * <tt>:args</tt> - Array of optional arguments for method. 1 is passed if :args not specified.
  #   * <tt>:field</tt> - Field name.
  # ====Example
  #   Call blogger_selector method and output results reveived from that method.
  #   @blogger=Blogger.find(:first) #=> {:id=>2,:blogger_name=>"Blogger Peter"
  #   params[:blogger_id] #=> 11
  #   cms_custom_field "blogger", :function=>"blogger_selector", :args=>[params[:bloger_id]],:field=>"blogger_name" #=>
  #   bloger_selector(2,"blogger_name",11)
  #
  #   @user=User.find(:first) #=> {:id=>1}
  #   cms_custom_field("user",:function=>"password_field_with_strength",:field=>"password") #=>
  #   password_field_with_strength("user",1,"password",1)
  def cms_custom_field object,options
    out=""
    if options[:function]
      if options[:args]
        options[:args].collect!{|element|
          if element.is_a?(String)
            "'#{element}'"
          else
            "#{element}"
          end
        }
      end
      #TODO ielikt speciālās funkcijas atbilstošajos modeļos
      out<<(eval("#{options[:function]}(#{instance_variable_get("@#{object}").id || 0},'#{options[:field]}',#{object},#{options[:args] ? options[:args].join(",") : "1"})")).to_s
    end
    out
  end

  # Create span with spefific content.
  # Receive _object_ as other field helper methods and options.
  # Accepted options:
  # * <tt>:table</tt> - Get object from foreign table otherwise use instance variable with _object_ name.
  # * <tt>:value</tt> - Use this option as span value, works only if *NOT* :titles passed
  # * <tt>:titles</tt> - Create input and label content from this options. If this is Array then
  #                      use #field_to_string_simple to get value if not then call it as method on _object_.
  # ====Example
  #     @blog=Blog.find(:first)
  #     @blog.user.name #=> John Deer
  #     cms_label_field "blog", :table=>"user", :titles=>"name" #=>
  #     <span class="object-label">John Deer</span>
  #     
  #     @blog.name #=> "Blog_22"
  #     cms_label_field "blog", :titles=>["My ",":name.upcase"] #=>
  #     <span class="object-label">My BLOG_22</span>
  #
  def cms_label_field object,options
    if options[:table]
      obj=options[:table].camelize.constantize
      object=obj.find(instance_variable_get("@#{object}").send("#{options[:table]}_id"))
    else
      object=instance_variable_get("@#{object}")
    end
    if options[:titles] && options[:titles].is_a?(Array)
      result=field_to_string_simple(options[:titles],object)
    else
      if options[:titles]
        result=object.send(options[:titles])
      elsif options[:value]
        result=options[:value]
      end
    end
    #content_tag('input',result,:type=>"text",:readonly=>"readonly",:class=>"txt")
    "<span class='object-label'>#{result}</span>"
  end

  # Create hidden field for given _object_ or with given values in options.
  # Accpted options:
  # * <tt>:field</tt> - Field that value is used as input value, not used when :value or :name is passed.
  # * <tt>:html</tt> - HTML options for field, not used when :name or :value is specified.
  # * <tt>:value</tt> - Special value not _object_ field value.
  # * <tt>:name</tt> - Hidden field name, default is name, that links field with _object_, value not taken from _object_.
  # ====Example
  #     cms_hidden_field "blog", :field=>"name" #=> <input type="hidden" name="blog[name]" value="blogname"/>
  #     cms_hidden_field "blog", :value=>"1", :name=>"temp_id" #=> <input type="hidden" name="temp_id" value="1"/>
  def cms_hidden_field object,options
    if options[:value] || options[:name]
      name=options[:name]||"object[#{options[:field]}]"
      "<input type='hidden' name='#{name}' value='#{options[:value]}'/>"
    else
      hidden_field object,options[:field],options[:html]
    end
  end

  # Create text field, call Rails text_field with given object.
  # Accpeted options:
  # * <tt>:field</tt> - Field name.
  # * <tt>:html</tt> - HTML options.
  # ====Example
  #     cms_text_field "blog", :field=>"name" #=>
  #     <input type="text" name="blog[name]" value="blogname"/>
  def cms_text_field object,options
    text_field object, options[:field], options[:html]
  end

  # Create check box group, mostly used for many-to-many relation.
  # Receive object name and options.
  # Accpted options:
  # * <tt>:field</tt> - Association name.
  # * <tt>:find_options</tt> - Find options if need to indicate specific records.
  # * <tt>:titles</tt> - See #field_to_string_simple.
  # ====Example
  #     Create checkbox group of roles that not built in.
  #     cms_checkboxgroup_field "user", :field=>"roles", :find_options=>{:conditions=>{:built_in=>false}}
  def cms_checkboxgroup_field object,options
    base_element=instance_variable_get("@#{object}")
    elements=base_element ? base_element.send(options[:field]) : []
    remote_class=base_element.class.reflect_on_association(options[:field]).klass
    remote_elements=remote_class.find(:all,options[:find_options]) if remote_class
    result=""
    remote_elements.each{|element|
      r=check_box_tag("#{object}[#{options[:field]}_ids][]", element.id,elements.include?(element),{:id=>"#{options[:field]}_#{element.id}"})
      r+=%(<label for="#{options[:field]}_#{element.id}" >#{field_to_string_simple(options[:titles],element)}</label>)
      result += "<div class=\"checkbox\">#{r}</div>"
    }
    result
  end

  # Create select field. Select might use remote data or specific data. Also multiselect can be created.
  # Accepts object name and options.
  # Allowed options:
  # * <tt>:options</tt> - Specific options data used in select.
  # * <tt>:html</tt> - HTML options.
  # * <tt>:include_blank</tt> - Include blank select option or not.
  # * <tt>:multiple</tt> - Create multiselect or not.
  # * <tt>:field</tt> - Field of _object_.
  # * For specific options and used see #get_data_for_select_field and #get_current_value_for_select_field.
  # ====Example
  #     Create select field for post, to allow choose user, by default there none of users are selected, and allow to select
  #     users that are registered, user is selected by user name and last name.
  #     cms_select_field "post", :field=>"user_id",:include_blank=>true,:table=>"Users", :find_options=>{:registered=>true}, :titles=>[":name"," ",":last_name"]
  def cms_select_field object,options
    options[:options]=options[:options].call if options[:options].is_a?(Proc)
    select_options=options[:options].is_a?(String)? options[:options] : get_data_for_select_field(options).collect{|row| row[0].is_a?(Symbol) ? [t(row[0]),row[1]] : row}
    current_value=get_current_value_for_select_field(object,options)
    current_value=current_value.is_a?(Symbol) ? t(current_value) : current_value
    class_name="select"
    class_name=options[:parent_link] ? "select-parented" : class_name
    options[:html][:class]="#{options[:html][:class]} #{class_name}"
    if options[:unlinked]
      options[:html][:class]=options[:html][:class]+(options[:multiple] ? " multiple" : "")
      select_options=[["-",0]]+select_options if options[:include_blank] && options[:options].is_a?(Array)
      select_tag("#{object}[#{options[:field]}]#{options[:multiple] ? "[]" : ""}",options_for_select(select_options,current_value),options[:html].merge({:multiple=>options[:multiple]}))+
        ((options[:parent_link] && !options[:multiple])?(cms_link(image_tag("/lolita/images/icons/add.png",:alt=>"+"),'GET',:action=>'create',:controller=>((options[:namespace]?(options[:namespace]+"/"):"")+options[:field].to_s.sub( /_id/, "")), :params=>{:set_back_url=>true},:html=>{:class=>'object-select-add'})):"")+
        (options[:multiple] ? "<br/><sup class='detail'>#{"lai iezīmētu vairākas rindas turiet nospiestu Crtl"}</sup>" : "")
    else
      "<table><tr>"+
        content_tag('td',select(object.to_sym,options[:field].to_s,select_options,{:include_blank=>options[:include_blank],:selected=>current_value}, options[:html]))+
        ((options[:parent_link])?(content_tag('td',cms_link(image_tag("/lolita/images/icons/add.png",:alt=>"+"),'GET',:action=>'create',:controller=>((options[:namespace]?(options[:namespace]+"/"):"")+options[:field].to_s.sub( /_id/, "")), :params=>{:set_back_url=>true},:html=>{:class=>'object-select-add'}))):"")+
        "</tr></table>"
    end
  end

=begin rdoc
  Renders a +has_and_belongs_to_many+ relationship in form of a
  list of existing associated records and <select> of other possibilities.

  Accepts a hash or list of parameters. The only obligatory is:
  
  * <tt>:field</tt> - attribute to access associated objects,
  should be of <i>{singularized}</i>_ids form, e.g. :+equipment_ids+
  or will be autoconverted from pluralized form, e.g.
  :+equipments+=>:+equipment_ids+

  Optional parameters:
  * <tt>:title</tt> - to override label, which by default is <tt>t(".{field}")</tt>
  * <tt>:object</tt> - parent object, e.g. :+product+, default is <tt>'object'</tt>
  * <tt>:existing</tt> - 
    * an array of [+title+,+id+,[+css_class+]] for display of existing items in the list
    * :+symbol+ of method to get them for current object.
    If absent, expects an "@{:+object+}" (e.g. <i>@product</i>) variable to be present and collects

    <tt>[{:property},{singularized property}]</tt> of the plularized form of specified field e.g.
      field=:product_ids,{:object=>:batch,:property=>:price}
    results in
      :existing=>@batch.products.collect{|product| [product.price,product.product_id]}
  * <tt>:property</tt> - only used in case of missing <tt>:existing</tt>
  * <tt>:suggest</tt> - other possible elements in the control area
    * an array of [+title+,+value+,[+css_class+]], usually <tt>object.attribute</tt> less :+existing+
    * or :+symbol+ method to return such array.
  * <tt>:possible</tt> - if :+suggest+ absent, a collection of elements to filter :+suggest+ from, e.g.
      :existing=>@batch.products.collect{...},:possible=>Products.all
  
    If both :+suggest+ and :+possible+ are absent, <i>{field}.all</i> is assumed, e.g.
      multi_select(:car_class_ids)
    is equivalent to:
      :existing=>@object.car_classes ...
      :possible=>CarClass.all
      :suggest=>:possible less :existing by comparing their ids
  * :maximum - maximum elelements allowed. The model should contain according 
    <tt>validates_length_of attributes,:maximum=>?</tt> limit.
  * <tt>:limit</tt> - <tt>{:css_class=>number, ...}</tt>

    Additional limit on specific elements can be set via assigning them a css class name
    in both +existing+ and +suggest+ elements. The list automatically switches to numbered on display.
  * <tt>:template</tt> - future element template to use instead of standard.
    Placeholders for {+text+}, {+attr+}, {+value+} will be substituted by JavaScript.
  
  Examples.
  * Show list of existing @object.equipments and other possible from Equipment.all:

      multiedit_select(:equipments)

  * Limit list of object equipments to a specified number, and among them, allow up to three
    combo equipments.
  
      multiedit_select(
        :equipment_ids, #field

        t(:".car_equipments"), #title

        :maximum=>CarClass::maximum_equipment_count, #maximum of equipments allowed

        #elements to show in the list, note passing the css class 'combo'
        :existing=>@object.equipments.collect{|equip|
        [
          "#{equip.name}#{equip.is_combo? ? ' (combo)':''}",
          equip.equipment_id,
          equip.is_combo? ? 'combo' : ''
        ]},

        #these will be displayed in the select control for adding
        :suggest=>Equipment.excluding(@object.equipments).collect{|equip|
        [
          "#{equip.name}#{equip.is_combo? ? ' (combo)':''}",
          equip.id,
          equip.is_combo? ? 'combo' : ''
        ]},

        #limit element count with the css class 'combo' to three
        :limit=>{:combo=>3}
     )
=end
  def cms_multi_select_field(hsh={})
    field=hsh[:field]
    field="#{field.to_s.singularize}_ids" unless field.to_s.match('_ids')
    hsh[:title]||=t(".#{field}")
    hsh[:object]||='object'
    hsh[:attribute]||=field
    hsh[:property]||=:name
    [:existing,:suggest].each{|key|
      hsh[key]=eval("@#{hsh[:object]}").send(hsh[key]) if hsh[key].is_a?(Symbol)
    }
    hsh[:existing]=eval("@#{hsh[:object]}").
      send( hsh[:attribute].to_s.gsub('_ids','').pluralize ).collect { |item|
      [item.send(hsh[:property]),item.send(hsh[:attribute].to_s.singularize)]
    } if hsh[:existing].nil?
    hsh[:possible]=hsh[:attribute].to_s.gsub('_ids','').
      camelize.constantize.all if hsh[:suggest].nil? && hsh[:possible].nil?
    if hsh[:suggest].nil? && hsh[:possible]
      ids=hsh[:existing].collect {|option| option[1] }
      filtered=hsh[:possible].reject { |item| ids.include?(item.id) }
      hsh[:suggest]=filtered.collect {|item| [item.send(hsh[:property]),item.id]}
    end
    render(:partial=>"managed/multi_select",:locals=>{:hsh=>hsh},:layout=>false)
  end

=begin rdoc
  Allows editing/creating <tt>has_many</tt> associated records.

  Accepts a hash or list of parameters, the only obligatory is:

  * field - attribute to access associated objects, should be of pluralized form, e.g. <tt>:equipment_options</tt>.
   
  Otional parameters:

  * <tt>:title</tt> - to override label, which by default is <tt>t(".{field}")</tt>
  * <tt>:object</tt> - parent object, e.g. :+product+, default is <tt>:object</tt>
  * <tt>:property</tt> - attribute of the bound object for input, default is <tt>:name</tt>
  * <tt>:existing</tt> - an array of [+title+,+id+] for display of existing items in the list.

    If absent, expects "@{:object}" (e.g. <i>@product</i>) variable to be present and collects
    <tt>[{:property},id]</tt> of the specified field, e.g.
      multi_input(:products,:object=>:batch,:property=>:price)
    results in
      :existing=>@batch.products.collect{|product| [product.price,product.id]}
  * <tt>:maximum</tt> - maximum elelements allowed. The model should contain according
    <tt>validates_length_of attributes,:maximum=>?</tt> validation.
  * <tt>:template</tt> - future element template to use instead of standard.
    Placeholders for <tt>{text}, {attr}, {value}</tt> will be substituted by JavaScript.
  
  <b>NOTE:</b> if you need to override how the values are manipulated, create according methods in your model that are named:
      multi_input_new_{attr}= (e.g. multi_input_new_products=)
      multi_input_existing_{attr}=
      multi_input_deletable_existing_{attr}=
=end
  def cms_multi_input_field(hsh={})
    hsh[:title]||=t(".#{hsh[:field]}")
    hsh[:object]||='object'
    hsh[:attribute]||=hsh[:field]
    hsh[:property]||=:name
    [:existing,:suggest].each{|key|
      hsh[key]=eval("@#{hsh[:object]}").send(hsh[key]) if hsh[key].is_a?(Symbol)
    }
    hsh[:existing]=eval("@#{hsh[:object]}").send(hsh[:attribute]).collect { |item|
      [item.send(hsh[:property]),item.id]
    } if hsh[:existing].nil?
    render(:partial=>"managed/multi_input",:locals=>{:hsh=>hsh},:layout=>false)
  end

  # Get current value for #cms_select_field.
  # Receive object name and options.
  # Accepted options:
  # * <tt>:without_default_value</tt> - Determinate that there's no default value.
  # * <tt>:default_value</tt> - Use specified value as default.
  # * <tt>:field</tt> - Get value from _object_ field.
  def get_current_value_for_select_field object,options={}
    if options[:without_default_value]
      nil
    else
      if options[:default_value]
        options[:default_value]
      else
        obj=instance_variable_get("@#{object}")
        obj.send(options[:field].to_s) if obj
      end
    end
  end

  # Collect data for #cms_select_field and create HTML options or return data.
  # Accepted options:
  # * <tt>:options</tt> - User create options for select, :find_options and :table are not used
  # * <tt>:table</tt> - Table that data is taken.
  # * <tt>:simple</tt> - If set to true return only data, no HTML.
  # * <tt>:find_options</tt> - Used to find not all records.
  # * <tt>:titles</tt> - See #field_to_string_simple.
  def get_data_for_select_field options={}
    data=options[:options] || options[:table].to_s.camelize.constantize.find(:all,options[:find_options])
    options[:simple] ? data : cms_simple_options_for_select(data,options[:titles])
  end

  
  def render_video url
    # vimeo
    url = url.gsub(/(http:\/\/(www\.)?vimeo\.com\/(\d+)\/?)/){|m|
      %^
      <p>
      <object width=400 height="225"
          data="http://www.vimeo.com/moogaloop.swf?clip_id=#{$3}&amp;server=www.vimeo.com&amp;show_title=1&amp;show_byline=1&amp;show_portrait=0&amp;color=00ADEF&amp;fullscreen=1"
          type="application/x-shockwave-flash">
        <param name="allowfullscreen" value="true" />
        <param name="allowscriptaccess" value="always" />
        <param name="movie" value="http://www.vimeo.com/moogaloop.swf?clip_id=#{$3}&amp;server=www.vimeo.com&amp;show_title=1&amp;show_byline=1&amp;show_portrait=0&amp;color=00ADEF&amp;fullscreen=1" />
      </object>
      </p>
      ^
    }
    # youtube
    url = url.gsub(/(http:\/\/)?(www\.)?youtube\.com\/(watch\?v=([^&\s\/]+)|v\/([^&\s\/]+))[^\s\/]*\/?/){|m|
      code = $4 || $5
      %^
      <p>
      <object type="application/x-shockwave-flash" style="width:400px; height:225px;"
        data="http://www.youtube.com/v/#{code}">
        <param name="movie" value="http://www.youtube.com/v/#{code}" />
      </object>
      </p>
      ^
    }
  end
end
