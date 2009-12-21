module ControllerExtensions
  module Cms
    # Creates and displays a list of entries.
    module List
      # When _controller_ is subclass of #Managed than, this is default action used to render entries list.
      # All list configuration goes in config[:list] like config[:list][:top_partials]=[]
      # List accepts following configuration
      # * <tt>:top_partials</tt> - Are partials that is rendered in +list_template+ before form
      # * <tt>:botttom_partials</tt> - Are partials that is rendered in +list_template+ after_form
      # * <tt>:include</tt> - Is used to create +SQL+ joins when <tt>:parents</tt> is set.
      # ====Examples
      #     :parents=>[:user_id,:blog_id]
      #     <i>Specific sql can be indicated or Symbol to automaticaly create sql</i>
      #     :include=>{:user_id=>"INNER JOIN users ON users.id=table.author_id",:blog_id=>:blog_id}
      # * <tt>:parents</tt> - Array of allowed *params*, when given than is used to create +SQL+ joins.
      # ====Example
      #     :parents=>[:user_id,:blog_id]
      # * <tt>:sort_column</tt> - Sort column(-s) name.
      # ====Example
      #     "name" or "name AND surname"
      # =====Default
      #     "created_at"
      # * <tt>:sort_direction</tt> - Sort direction ascending (asc) or descending (desc). Default +desc+
      # * <tt>:per_page</tt> - How many records are in page.
      # * <tt>:object</tt> - Object that is used as model name.
      # ====Example
      #     "user" #=> User
      # * <tt>:parent_name</tt> - Used for session to keep controller information about page
      # ====Example
      #    "translate"
      # * <tt>:filter</tt> - Same as <tt>:conditions</tt> in find. Can be _String_ or _Array_
      # * <tt>:group</tt> - Like <tt>:group</tt> in find method.
      # * <tt>:partial</tt> - Partial template name used to render _list_. Default +form+.
      # * <tt>:layout</tt> - Layout name used to render _list_ action (may be *false*). Defautl <i>/cms/default</i>

      def list configuration={}
        params[:action]="list" unless configuration[:keep_action]
        handle_function "before_list"

        prepare_list(configuration) do |object,options|
          @accepted_params={} #glabā tās vērtības kas ir pieņamtas kā saistīto moduļu filtri

          filter_and_include_sql(object) do |filter_sql,parent_column,join_sql|
            options[:conditions]=object.cms_merge_conditions(options[:conditions],filter_sql)
            options[:joins]<<join_sql
            @accepted_params[parent_column]=my_params[parent_column]
          end

          sort_options(object,options) do |columns,direction,joins|
            options[:sort_column]=columns ? columns.join(",") : nil
            options[:sort_direction]=direction
            #params_keeper[:sort_column]=
            options[:joins]+=joins if joins && !joins.empty?
          end if @config[:list] && @config[:list][:sortable]

          options[:per_page]=(@config[:list] ? @config[:list][:per_page] : nil) || (object.respond_to?(:per_page) ? object.per_page : nil)
          options[:page]=params[:page]
          options[:joins]=options[:joins].uniq_joins.join(" ") if options[:joins].is_a?(Array)
          unless configuration[:report] || @config[:list][:report]
            @page=paging object, options
          else
            @page=object.find(:all,:conditions=>options[:conditions],:joins=>options[:joins],:group=>options[:group],:order=>options[:sort_column] ? "#{options[:sort_column]} #{options[:sort_direction]}" : nil)
          end
          handle_function "after_list"
          if configuration[:report] || @config[:list][:report]
            return @page
          else
            render_list(local_variables_for_partial)
          end
          #TODO uztaisīt lai var arī tikai izkalkulēt bez renderēšanas
        end
      end

      private

      # Used in #list action.
      # Create default options and get _module_ and yields to #list.
      def prepare_list configuration
        obj=@config[:object] ? @config[:object].camelize.constantize : object
        opt=@config[:list]
        opt=opt.merge({
          :conditions=>@config[:list] ? @config[:list][:conditions] : [],
          :joins=>obj.join_symbols_to_string(@config[:list][:joins] || []),
          :ferret_filter=>ferret_filter(obj),
          :advanced_filter=>params[:advanced_filter],
          :simple_filter=>params[:ferret_filter]
        }).merge(configuration)
        yield obj,opt
      end
      # When receiving in *params* values that ends with <i>_id</i>, then create <tt>INNER JOIN</tt>
      # with corresponding tables.
      # Joins are created only when :parents are specified.
      def filter_and_include_sql object
        @config[:parents].each{|parent_column|
          #-1 ir reset, tjipa rāda atkal visus
          if (params.include?(parent_column) && params[parent_column]) && params[parent_column].to_i!=-1
            #@parent_params[parent_column]=params[parent_column]
            if @config[:list][:include][parent_column].is_a?(Symbol)
              include=object.build_join_sql(parent_column,:join_type=>"INNER JOIN")
            else
              include=@config[:list][:include][parent_column]
            end if @config[:list][:include] && @config[:list][:include].include?(parent_column)
            filter="`#{object.table_name}`.`#{parent_column}`=#{params[parent_column].to_i}"
            yield filter,parent_column,include
          end
        } if @config[:parents]
      end

      # Yield <tt>sort_column</tt>, <tt>sort_directions</tt> and <tt>join_statement</tt> when
      # sorting by remote field.
      def sort_options obj,options
        if params[:sort_column]
          column,direction=params[:sort_column],params[:sort_direction]
        else
          column,direction=default_sort_options
        end
        join_statement,sort_column=obj.complex_sort(column.to_s.split(","),@config[:parents])
        yield sort_column,direction,join_statement
      end

      # Yield default <tt>sort_column</tt> and <tt>sort_direction</tt>
      def default_sort_options
        sort_column=@config[:list][:sort_column]
        sort_direction=@config[:list][:sort_direction]
        if !sort_column && @config[:list][:columns]
          default_col=@config[:list][:columns].find{|column| column[:default]}
          default_col=@config[:list][:columns].find{|column| column[:sortable]} unless default_col
          sort_column=default_col ? default_col[:field] : nil
          sort_direction=default_col && default_col[:sort_direction] ? default_col[:sort_direction] : (default_col ? "asc" : nil)
        end
        return sort_column,sort_direction
      end

      # Render <b>:partial</b> of entries or displays report.
      def render_list locals={}
        unless @config[:report]
          partial=params[:advanced_filter].is_a?(Hash) ||  params[:paging].to_b ? locals[:partial] : "/cms/list_template"
          unless request.post? || request.xml_http_request? || params[:is_ajax].to_b
            render :partial=>partial, :layout=>@config[:list][:layout] ? @config[:list][:layout] : "cms/default",:object=>locals #TODO pielikt lai katram namespace savs layout
          else
            render :partial=>partial,:layout=>false,:object=>locals
          end
        else
          render_report
        end
      end

      # Return Hash or variables needed for <em>list_template</em>.
      def local_variables_for_partial
        {
          :page=>@page,
          :refresh_menu=>@config[:refresh_menu],
          :list_action=>params[:action], #ja nu gadījumā tas nav list
          :partial=>get_partial_form,
          :params=>@accepted_params,
          :container=>@config[:list][:container],
          :advanced_filter=>get_advanced_filter
        }
      end

      # Return partial form.
      def get_partial_form
        @config[:list][:partial]==:default ? "/cms/list_default" : @config[:list][:partial] || "list"
      end

      # Return <em>ferret_filter</em> when ferret is enabled for current _object_ class.
      def ferret_filter obj
        obj.respond_to?('ferret_enabled?') && obj.ferret_enabled? && params[:ferret_filter].to_s.size>0 ? params[:ferret_filter] : nil
      end

      # Set advanced filter. Deprecated.
      def get_advanced_filter
        params[:advanced_filter]=params[:advanced_filter].is_a?(Hash) && params[:advanced_filter][:clear_filter] ? nil : params[:advanced_filter] # lai attīrot no filtra renderētu pilno formu
        params[:advanced_filter]=params[:advanced_filter] && (((params[:advanced_filter].is_a?(Hash) || params[:advanced_filter].is_a?(Array)) && !params[:advanced_filter].empty?)  || params[:advanced_filter].to_i.to_s.size==params[:advanced_filter].to_s.size ) ? params[:advanced_filter] : nil
        params[:advanced_filter]
      end

    end
  end
end