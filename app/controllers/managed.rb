# Manage system requests for CRUD actions and others (See #ControllerExtensions for detail)
# See #Lolita::ManagedCallbacks for supported callbacks in _Managed_ controllers.
class Managed < ApplicationController
  include ControllerExtensions::Cms::Paging
  include ControllerExtensions::AdvancedFilterExtension
  include ControllerExtensions::Cms::HandleRelations
  include ControllerExtensions::Cms::HandleMenu
  include ControllerExtensions::Cms::List
  include ControllerExtensions::Cms::PublicView
  include ControllerExtensions::Cms::HandleMetadata
  include ControllerExtensions::Cms::HandleParams
  include ControllerExtensions::Cms::HandleSpecialFields
  include ControllerExtensions::Cms::Reports
  include ControllerExtensions::Cms::Crud
  include ControllerExtensions::Cms::Callbacks
  include ControllerExtensions::Cms::HandleErrors
  include ControllerExtensions::Cms::Language if Lolita.config.i18n(:translation)

  managed_after_open :set_instance_variable_for_nested_attributes

  # Redirect to _update_ action when params[:id] is set otherwise to _list_ action.
  def open
    get_id.to_i>0 ? redirect_to(params.merge(:action=>:update)) : list
  end
  
  protected

  # Used to set #Managed kind params after allowed action to #Managed controller.
  def after_allow
    handle_params
  end

  # Return @my_params, that is cloned params, but can be modified leaving _params_ unchanged.
  def my_params
    @my_params
  end

  def process_options # :nodoc:
    @config=config
    @config[:on_complete]=@config[:on_complete] || "$('#{'#content'}').html(data)"
  end

  # In every #Managed controller *conf* method should be created to set _configuration_.
  # Configuration must be <i>Hash</i>. Allowed configuration values.
  # * <tt>:object</tt> - Set another <i>class name</i> that is used for records finding. Default is create form params[:controller]
  # * <tt>:tabs</tt> - Array of tabs configuration, this information is used to create new, edit form. Allowed tab <b>:type</b>:
  #   * Common options for tabs:
  #     * <tt>:in_form</tt> - Is tab generated in main form, not needed for <i>:multimedia</i>.
  #     * <tt>:fields</tt> - Array of tab field or <i>:default</i> to use fields from :fields, not used for <i>:multimedia</i>.
  #     * <tt>:opened</tt> - Is tab opened after form opening. Only first tab with this option will be opened.
  #     * <tt>:opened_on_load</tt> - Is tab opened when loading form. Useful when need to calculate DOM elements dimensions.
  #     * <tt>:title</tt> - Specific title for tab.
  #     * <tt>:object</tt> - Used to create nested form. Often used when <i>nested_attributes_for</i> is set, don't need for <i>:multimedia</i>. Example: "profile".
  #     * <tt>:partial</tt> - Form name that is used to generate tab, don't need for :multimedia. Example: "translate" or :default.
  #     * <tt>:partials</tt> - Hash of partials:
  #       * <tt>:before</tt> - Array of partials that been rendered before tab form.
  #       * <tt>:after</tt> - Array of partials that been rendered after tab form.
  #   * <tt>:metadata</tt> - Tab for #Metadata information for current entity, only one allowed.
  #   * <tt>:multimedia</tt> - Tabs for #Multimedia information. Allowed <b>:multimedia</b> types:
  #     * Common :multimedia options, not used but might be in different media thang file kind:
  #       * <tt>:configuration</tt> - Used for <i>file</i> type multimedia:
  #         * <tt>:height</tt> - File list height, default 390.
  #       * <tt>:single</tt> - Is only one file need to be kept.
  #     * <tt>:image_file</tt> - Tab for #Media::ImageFile. Accepted options:
  #       * <tt>:main_image</tt> - Is main image can be set.
  #     * <tt>:video_file</tt> - Tab for #Media::VideoFile. Accepted options:
  #       * <tt>:with_intro</tt> - Is intro need to be created.
  #     * <tt>:simple_file</tt> - Tab for #Media::SimpleFile.
  #     * <tt>:audio_file</tt> - Tab for #Media::AudioFile.
  #     * <tt>:google_map</tt> - Tab form #Media::GoogleMap. Accpeted options:
  #       * <tt>:unique_id</tt> - Unique ID to create multiple maps for entity.
  #   * <tt>:translate</tt> - Translate tab for entity, will show on existing entities.
  #   * <tt>:content</tt> - Tab for entity data.
  #   * <tt>:default</tt> - Like :content, only need to set common options.
  # * <tt>:list</tt> - Configuration for _list_ action:
  #   * <tt>:options</tt> - Icons that are displayed in last column, allowed - :edit, :destroy
  #   * <tt>:sortable</tt> - Is all columns sortable.
  #   * <tt>:dateformat</tt> - Set date format if column has #DateTime type. Example: "%y/%m/%d".
  #   * <tt>:intro</tt> - Intro text in top of page.
  #   * <tt>:include</tt> - Hash where :key is foreign key and :value is table name, that be included if receive params that match :key.
  #   * <tt>:sort_column</tt> - Default sort column, will be excluded if :column is set, default - "created_at".
  #   * <tt>:sort_direction</tt> - Default sort direction _asc_ or _desc_, default: _desc_.
  #   * <tt>:partial</tt> - Partial form name, by default looks in current view directory for <i>list.html</i>. If :default is set then default cms partial will be rendered.
  #   * <tt>:columns</tt> - Array of visible columns, useful when :default partial is set. Allowed options:
  #     * <tt>:default</tt> - Is default field that is used for sorting.
  #     * <tt>:width</tt> - Column width in pixels(px).
  #     * <tt>:title</tt> - Column title by default humanized DB field name.
  #     * <tt>:link</tt> - Is _edit_ action link will be generated.
  #     * <tt>:field</tt> - Field name, for related objects Array can be set. Example: "name" or ["profile","name"].
  #     * <tt>:function</tt> - Function that be called to get cell value.
  #     * <tt>:sort_direction</tt> - Sort direction by default _asc_.
  #     * <tt>:sort_field</tt> - Field that is used in place of original. Example: "name_index".
  #     * <tt>:sortable</tt> - Is field sortable, don't need to set if :default already is set.
  #     * <tt>:localize</tt> - Localize cell value, by default true.
  #     * <tt>:format</tt> - If column type is #DateTime, Example: :default or :short or :long or "%d.%m".
  # * <tt>:fields</tt> - Array with fields is used when any of tabs :fields value is set to :default allowed options:
  #   * <tt>:type</tt> - Field type see Extensions::FieldHelper#field_render
  #   * <tt>:field</tt> - Field name.
  #   * <tt>:title</tt> - Field title by default column_name is used.
  #   * <tt>:html</tt> - HTML options that might be used to set field HTML element options.
  #   * <tt>:object</tt> - Object name that is used insted of :object, like nested attributes object name.
  #   * <tt>:function</tt> - Only for :custom type fields. See Extensions::SingleFieldHelper#cms_custom_field.
  #   * <tt>:args</tt> - Only for :custom type fields.
  #   * <tt>:table</tt> - Table name used when data for remote table need to be collected mostly used with :select type.
  #   * <tt>:find_options<tt> - Find options for remote records finding.
  #   * <tt>:titles</tt> - String or Array, that be used with :label or :select type fields. See Extensions::FieldHelper#field_to_string_simple.
  #   * <tt>:without_default_value</tt> - Only for :select type field, means that doesn't have current value.
  #   * <tt>:config</tt> - Specific options for :date and :datetime field types.
  #   * <tt>:options</tt> - Options for :select field. Example: [["name",id]].
  #   * <tt>:simple</tt> - Specifies that has :options passed for :select type field. Translation is passed as labda{}.
  #   * <tt>:default_value</tt> - Default value for :select type field, if current not been found.
  #   * <tt>:parent_link</tt> - Link to parent entity. Deprecated.
  #   * <tt>:multiple</tt> - Is select used as multiselect.
  #   * <tt>:unlinked</tt> - Is element linked with current _object_ for :select. Deprecated.
  #   * <tt>:namespace</tt> - Namespace name if differs from current for :select. Depracated.
  #   * <tt>:include_blank</tt> - Is blank option included in all options for :select.
  #   * <tt>:translate</tt> - Is field translatable, if set to _true_ than shown in :translate tab.
  #   * <tt>:roles</tt> - Define roles that can or can not edit field:
  #     * <tt>:include</tt> - Array or Hash or roles that are allowed to edit field. See Extensions::FieldHelper#can_edit_field?
  #     * <tt>:exclude</tt> - As :include only for excluding
  #   * <tt>:actions</tt> - Define actions when field is editable and when not, other options as :roles. See Extensions::FieldHelper#can_edit_field?
  def config
    {}
  end

  # Return array of field for tab.
  def tab_fields tab
    (tab[:fields] && tab[:fields]==:default ? @config[:fields] : tab[:fields] || [])
  end
  # Detect if object has given tab type.
  def has_tab_type? name
    @config[:tabs] && @config[:tabs].find{|tab| tab[:type]==name}
  end

  def current_fields # :nodoc:
    current_tab=@config[:tabs].find{|tab|
      tab[:object]==:object || tab[:type]==:content
    }
    current_tab[:fields]==:default ? @config[:fields] : current_tab[:fields]
  end

  # Return _object_ class name.
  def object
    @config[:object_class]
  end

  # Return Hash of template name and layout.
  def self_layout layout=false
    if !all_params
      handle_params
    end
    unless request.xhr? || params[:is_ajax].to_b
      layout='cms/default'
    end
    if @read_only
      {:template=>"managed/read",:layout=>layout}
    else
      {:template=>"managed/create",:layout=>layout}
    end
  end

  # Deprecated.
  def set_back_url 
    session[:start_links]=[] unless session[:start_links]
    if redirect_step_back?
      session[:start_links].push(params)
    else
      session[:start_links].clear
    end
  end

  # Deprecated.
  def redirect_step_back?
    session[:start_links] && !session[:start_links].empty? && my_params[:set_back_link].to_b
  end

  # Deprecated.
  def redirect_step_back
    next_url=nil
    if session[:start_links] && !session[:start_links].empty?
      while !next_url && !session[:start_links].empty?
        next_url=session[:start_links].pop
        if next_url
          redirect_to next_url
        end
      end
      if !next_url
        redirect_to additional_params
      end
    end
  end

  # Called when error raises in #Extensions::Managed::Crud
  def on_error existing=false
      params.delete(:temp_file_id)
      render self_layout
  end
  
  # Redirect after manipulating with _object_. Allowed actions:
  # * <tt>:only_render</tt> - Render only layout
  # * <tt>:layout</tt> - Layout name
  # * <tt>:error</tt> - Render form that show error.
  # * <tt>:step_bck</tt> - Redirect step back.
  def redirect_me options={}
    if options[:only_render]
      render options[:layout]
    else
      unless @config[:do_not_redirect]
        if options[:error]
          on_error !@object.new_record?
        elsif options[:step_back]
          redirect_step_back
        else
          redirect_to additional_params
        end
      end
    end
  end

end
