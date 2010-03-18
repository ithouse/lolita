# coding:utf-8 
# Define #Managed helper methods that is used to create CMS forms, filters and other stuff.
module ManagedHelper
  include Extensions::FieldHelper
  include Extensions::PagingHelper
  include Extensions::LinkHelper
  include Extensions::TranslationHelper

  # Render partials in <code>list</code> action.
  # Two +position+ is accepted:
  # * <tt>:top</tt>
  # * <tt>:bottom</tt>
  def render_partials position
    partials=@config[:list][:partials][position] if @config[:list] && @config[:list][:partials]
    partials || []
  end

  # Return default columns for object that data is displayed in <code>list</code> view.
  # Collect all columns and return Array of Hashes that is sames as provided by <code>@config</code>.
  def default_cms_columns
    obj=@object ? @object.class : params[:controller].camelize.constantize
    obj.columns.inject([]){|result,column|
      width=760/obj.columns.size + ([:string,:datetime].include?(column.type) ? 50 : (-50))
      result<<{:width=>width,:title=>column.name.humanize,:field=>column.name,:default=>obj.columns.first==column,:link=>true,:sortable=>true}
    }
  end

  # Return all tabs that Managed#config allow.
  # Expect block and options, work with #Managed and accpet specific options.
  # Take tabs and all tab information from <code>@config</code> that include all information
  # provided by <code>config</code> method including :tabs.
  # Method goes through all tabs and render that kind of partial that match given type or custom partial if given.
  # Following options are allowed:
  # * <tt>:in_form</tt> - Determine that now rendering into form, otherwise outside of form.
  # * For specific type tabs and custom created options is passed to related method and can more other
  # options can be provided.
  # ====Example
  #     tabs(:in_form=>true) do |tab_content|
  #       <%= tab_content %>
  #     end
  def tabs options={} # :yields: tab_content
    opened=false
    media_types=Media::Base.all_media_names.collect{|m| m.to_sym}
    special_types= [:metadata,:translate,:multimedia]
    @config[:tabs].each_with_index{|tab,index|
      tab[:index]=index
      tab_opened=(!opened && tab[:opened])|| tab[:opened_on_load]
      opened=tab_opened ? true : opened
      start_html,end_html=tab_start_end_html(tab,index,tab_opened)
      tab[:partial]="/managed/object_data" if tab[:type]==:content || tab[:type]==:default
      unless special_types.include?(tab[:type])
        yield %(#{start_html}#{render(:partial=>tab[:partial],:locals=>{:tab=>index})}#{end_html}).html_safe! if options[:in_form]==tab[:in_form]
      else
        if tab[:type]==:metadata
          yield %(#{start_html}#{render(:partial=>"/managed/meta_information",:locals=>{:tab=>index})}#{end_html}).html_safe! if options[:in_form]
        elsif tab[:type]==:translate
          yield %(#{start_html}#{render(:partial=>"/managed/translate",:locals=>{:tab=>index})}#{end_html}).html_safe! if is_translatable?(options)
        elsif tab[:type]==:multimedia && media_types.include?(tab[:media])
          if self.respond_to?(:"lolita_#{tab[:media]}_tab")
            yield "#{start_html}#{self.send(:"lolita_#{tab[:media]}_tab",options,tab)}#{end_html}".html_safe!
          else
            yield "#{start_html}#{default_lolita_media_tab(options,tab)}#{end_html}".html_safe!
          end
        end
      end
    }
  end

  # Determine whether to display translation tab.
  # Accept options with only one key <code>:in_form</code>.
  def is_translatable? options={}
    options[:in_form] && Lolita.config.i18n(:translation) &&  params[:action]=="update"
  end

  # Return tab start and end HTML.
  # Require +tab+ that is Hash from configuration, and +index+ for ordering tabs and
  # +opened+ can be passed to display tab or hide.
  # Also if <code>:partials</code> in tab Hash is given those will be rendered after start HTML
  # and before end HTML.
  def tab_start_end_html tab,index,opened=nil
    start_html=%(<div id="tab#{index}container" name="tab_content" style="display:#{opened ? "block" : "none"};">)
    tab[:partials][:before].each{|before_partial|
      start_html+=render(:partial=>before_partial,:locals=>{:tab=>index})
    } if tab[:partials] && tab[:partials][:before]
    end_html=""
    tab[:partials][:after].each{|after_partial|
      end_html+=render(:partial=>after_partial,:locals=>{:tab=>index})
    } if tab[:partials] && tab[:partials][:after]
    end_html+=%(<br class="clear"/><div><!--[if !IE]>for ie to expand height correctly<![endif]--></div></div>)
    return start_html.html_safe!,end_html.html_safe!
  end

  # Used to render specific HTML required for fields.
  # Now has effect when <code>:autcomplete</code> field is used.
  def add_fields_html() # :yields: field_html
    @config[:tabs].each{|tab|
      fields=fields_for_tab(tab)
      fields.each{|field|
        if field[:type].to_sym==:autocomplete && field[:add_new] && can_edit_field?(field)
          yield %(
          <div id="#{tab[:object]||:object}_#{field[:field]}_autocomplete_dialog" style="visibility:hidden">
              <div class="hd">#{t(:"fields.autocomplete.header")}</div>
              <div class="bd">
                <form method="POST" action="#{url_for(field[:add_new])}">
                  <label for="subject">#{t(:"fields.autocomplete.tag name")}:</label>
                  <input type="text" name="object[name]" size="30" maxlength="255" style="margin-bottom:3px;"/><br/>
                  <input type="button" class="btn" id="#{tab[:object]||:object}_#{field[:field]}_autocomplete_dialog_confirmation_button" value="#{t(:"actions.confirm")}"/>
                  <input type="button" class="btn" id="#{tab[:object]||:object}_#{field[:field]}_autocomplete_dialog_cancel_button" value="#{t(:"actions.cancel")}"/>
                </form>
              </div>
          </div>
          ).html_safe!
        end
      } if fields.respond_to?(:each)
    }
  end

  # Render tab headers, for each header see #tab_header.
  # Goes through all tabs and detect if it is open, that title and if that
  # tab need to be rendered now.
  def tab_headers # :yields: tab_header
    opened=nil
    @config[:tabs].each_with_index do |tab,index|
      tab_opened=tab[:opened] && !opened
      opened=tab_opened || opened
      tab[:title]=t(tab[:title]) if tab[:title] && tab[:title].is_a?(Symbol)
      if tab[:type]!=:translate || (tab[:type]==:translate && is_translatable?(:in_form=>true))
        yield tab_header(tab[:title] || (tab[:media] ? t(:"tabs.#{tab[:media]}") : t(:"tabs.#{tab[:type]}")), :index=>index,:current=>tab_opened).html_safe!
      end
    end
  end

  # Return tab header HTML.
  # Accepts +title+ and +options+
  # * <tt>:current</tt> - Determine whether tab is visible.
  # * <tt>:index</tt> - To detect witch tab to be opened when tab header is clicked. 
  def tab_header title,options={}
    index=options[:index]||rand
    current=options[:current] ? "current" : ''
    "<a id='tab#{index}' name='tab_header' class='#{current}' onclick="+'"'+"switch_tabs(this)"+'"'+">#{title}</a>".html_safe!
  end

  # Return title for field when +title+ is Symbol and in include dot(-s) then
  # translate it otherwise return +title+.
  def field_title title=nil
    if title.is_a?(Symbol) && title.to_s.split(".").size>1
      t(title)
    else
      title
    end
  end

  # Create table title from +controller+, try to find it in Admin::Table
  # otherwise humanize +controller+ name.
  def table_title controller
    table=Admin::Table.find_by_name(controller)
    table ? table.humanized_name : controller.humanize
  end

  # Create header cell for <code>list</code> action.
  # Accpted +options+:
  # * <tt>:params</tt> - Hash of params added to link:
  #   * <tt>:sort_direction</tt> - Direction that column data need to be sorted uses <code>params[:sort_direction]</code> see Extensions::PagingHelper#sort_direction
  #   * <tt>:sort_column</tt> - Column name that is used to sort data.
  # * <tt>:html</tt> - HTML added to link:
  #   * <tt>:class</tt> - Default "black".
  # * <tt>:sort_column</tt> - Shorter way to define <code>options[:params][:sort_column].
  # * <tt>:container<tt> - DOM element id that is used to put in response text, default "form_list".
  # * <tt>:title</tt> - Column visible title, uses #field_title to get well formated title.
  # * <tt>:width</tt> - Column width in px, may not be real width because of HTML table rendering.
  # Return <code>th</code> element.
  def list_header_cell options={}
    options[:params]||={}
    options[:html]||={}
    options[:html][:class]||="black"
    options[:params][:sort_direction]||=sort_direction
    options[:params][:sort_column]||=options[:sort_column] ? options[:sort_column].to_s : nil
    options[:container]||="form_list"
    options[:title]||=field_title(options[:params][:sort_column] || options[:title])
    content="#{(@config[:list][:sortable] && options[:params][:sort_column] ? list_link(options) : options[:title])}&nbsp;"
    content+=(
      if @config[:list][:sortable] && (options[:params][:sort_column] &&  (params[:sort_column] || session[current_session_name][:sort_column] || []).include?(options[:params][:sort_column]))
        if options[:params][:sort_direction]=="asc"
          image_tag("/lolita/images/cms/arrow_blue_s.gif",:alt=>"V")
        else
          image_tag("/lolita/images/cms/arrow_blue_n.gif",:alt=>"A")
        end
      else
        image_tag("/lolita/images/cms/bullet_blue.png",:alt=>"o")
      end
    )
    content_tag("th", content,:style=>options[:width] ? "width:#{options[:width]}px;" : nil).html_safe!
  end

  # Return formated <code>flash[:notice]</code> for #Lolita.
  def cms_flash_box
    if flash[:notice]
      %(<div class="greenbox">
        <div class="l">
          <div class="r">
            #{t(flash[:notice])}
          </div>
        </div>
      </div>
      <br class="clear" />
      ).html_safe!
    end
  end

  # Return links for +element+ (ActiveRecord object) with images for <code>:edit</code> and <code>:destroy</code> actions.
  # Options are taken from <code>@config[:list][:options]</code> see Managed#config.
  # ====Example
  #     list_options(Comment.find(1))
  def list_options element # :yields: link
    @config[:list][:options].each{|option|
      case option
      when :edit
        yield edit_link(:id=>element.id,:image=>true)
      when :destroy
        yield destroy_link(:id=>element.id, :image=>true)
      end
    } if @config[:list][:options]
  end

  # Create title for default #Managed views from controller or any other name.
  # Return title for create, update and list actions.
  # ====Example
  #     params #=> {:controller=>"comment", :action=>"update"}
  #     cms_title(params[:controller]) #=> Edit comment
  #     cms_title("Users") #=> Edit users
  def cms_title name
    name=name.gsub(/\//,"_")
    case params[:action]
    when "create"
      "New #{name.humanize.downcase}"
    when "update"
      "Edit #{name.humanize.downcase}"
    when "list"
      name.humanize.pluralize
    end
  end

  # Specific #Managed method, for _object_ create/edit form, that return escapted
  # JS to submit form when submit button clicked.
  def form_submit_action only_save=false
    result="submitForm(\"#object_form\",\"#{@config[:on_complete].gsub(/'/,"\\\\\"")}\",#{only_save});"
    result
  end

  # Call getter method on +element+ from +ary+.
  # When method return nil then return "--" or raise error, otherwise call next
  # method from +ary+ and so on until all methods are called, and then return
  # last method result.
  # ====Example
  #     send_method_array(comment, [:id,:text]) #=> return comment text value
  def send_method_array element,ary
    tempobj=element
    ary.each{|meth|
      begin
        tempobj=tempobj.send(meth)
        return "--" unless tempobj
      rescue
        raise "Error sending #{meth}, check managed list config :field for #{element}.#{ary.join(".")}"
      end
    }
    tempobj
  end
end

