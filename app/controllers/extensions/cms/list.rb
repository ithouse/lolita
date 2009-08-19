module Extensions
  module Cms
    module List
      # All list configuration goes in config[:list] like config[:list][:top_partials]=[]
      # List accepts following configuration
      #   :top_partials -are partials that is rendered list_template before form
      #   :botttom_partials - are partials that is rendered in list_template after_form
      #   :sort_column - sort column(-s) name.
      #     Example: "name" or "name AND surname"
      #     Default: "created_at"
      #   :sort_direction - direction withc to sort.
      #     Values: "asc" or "desc"
      #     Default: "desc"
      #   :per_page - how many records are in single page
      #   :object - object witch is used as model name.
      #     Example: "user"
      #   :overwrite - when you use filter in lists and is set :overwrite(must been set :object)
      #                fields are taken used :object as a Model.
      #   :parent_name - used for session to keep controller information about page
      #     Example: "translate"
      #   :filter - like :conditions, can be String or Array
      #   :filter_fields - ONLY fields included when you use filter in lists #not used
      #     Example: ['name','age']
      #   :group - like :group
      #   :partial - witch Template form used to render list
      #     Default: 'form'
      #     Example: 'my_form'
      #   :layout - withc Layout used to render view or false
      #     Default: '/cms/default'
      #     Example: 'my_template'

      def list configuration={}
        params[:action]="list" unless configuration[:keep_action]
        handle_before_functions "list"

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
          handle_after_functions "list"
          if configuration[:report] || @config[:list][:report]
            return @page
          else
            render_list(local_variables_for_partial)
          end
          #TODO uztaisīt lai var arī tikai izkalkulēt bez renderēšanas
        end
      end

      private

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
      # Saņemot parametros vērtību ar nosaukumu, kas atbilst kādam no norādītajiem vecāka elementiem
      # [:user_id,:news_id] utt. Izveido INNER JOIN sql un iekš WHERE ieliek tabulas_nosaukums.user_id=vērtība.to_i
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

      def sort_options obj,options
        if params[:sort_column]
          column,direction=params[:sort_column],params[:sort_direction]
        else
          column,direction=default_sort_options
        end
        join_statement,sort_column=obj.complex_sort(column.to_s.split(","),@config[:parents])
        yield sort_column,direction,join_statement
      end

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

      def render_list locals={}
        unless @config[:report]
          partial=params[:advanced_filter].is_a?(Hash) ||  params[:paging].to_b ? locals[:partial] : "cms/list_template"
          unless request.post? || request.xml_http_request? || params[:is_ajax].to_b
            render :partial=>partial, :layout=>@config[:list][:layout] ? @config[:list][:layout] : "cms/default",:object=>locals #TODO pielikt lai katram namespace savs layout
          else
            render :partial=>partial,:layout=>false,:object=>locals
          end
        else
          render_report
        end
      end

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

      def get_partial_form
        @config[:list][:partial]==:default ? "/cms/list_default" : @config[:list][:partial] || "list"
      end

      def ferret_filter obj
        obj.respond_to?('ferret_enabled?') && obj.ferret_enabled? && params[:ferret_filter].to_s.size>0 ? params[:ferret_filter] : nil
      end
      
      def get_advanced_filter
        params[:advanced_filter]=params[:advanced_filter].is_a?(Hash) && params[:advanced_filter][:clear_filter] ? nil : params[:advanced_filter] # lai attīrot no filtra renderētu pilno formu
        params[:advanced_filter]=params[:advanced_filter] && (((params[:advanced_filter].is_a?(Hash) || params[:advanced_filter].is_a?(Array)) && !params[:advanced_filter].empty?)  || params[:advanced_filter].to_i.to_s.size==params[:advanced_filter].to_s.size ) ? params[:advanced_filter] : nil
        params[:advanced_filter]
      end
      #beidzas modulis
    end
  end
end