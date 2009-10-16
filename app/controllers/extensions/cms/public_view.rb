module Extensions
  module Cms
    module PublicView
      
      # Configuration is received through managed configuration :public attribute.
      # Common attributes for #show and #index actions, that are recieved through :public.
      #   :template - template name to render, default "show"
      #   :layout - layout name to render, default false
      #   :on_error_url - URL to redirect when #Exception raised, default home_url
      #   :single - must be set to true
      #   :conditions - find conditions
      #
      # Default #Managed function for single resource handling.
      # Default #show action works only if :single atrribute is set to True.
      def show
        handle_function "before_show"
        @object=object.find(get_id,:conditions=>@config[:public][:conditions])
        handle_function "after_show"
        render :action=>@config[:public][:template]||"show", :layout=>@config[:public][:layout]
      end

      # Default #Managed action for many resources.
      # Work only if :single attribute is set to False
      # Accpted attributes
      #   :sort_column - sort column
      #   :sort_direction - sort direction, "asc" or "desc"
      #   :joins - array of joins, sql format
      #   :per_page - record count in one page
      def index
        handle_function "before_show"
        join,sort_columns=public_sort_column
        @page=object.paginate(
          :conditions=>@config[:public][:conditions],
          :sort_directions=>public_sort_direction,
          :joins=>((@config[:public][:joins] || [])+(join||[])).uniq,
          :sort_column=>sort_columns,
          :per_page=>@config[:public][:per_page],
          :page=>params[:page].to_i
        )
        handle_function "after_show"
        render :action=>@config[:public][:template]||"show", :layout=>@config[:public][:layout]
      end
      
      private

      def public_sort_column
        if params[:sort_column]
          parents=object.reflections.collect{|name,reflection|
            reflection.macro==:belongs_to ? (reflection.primary_key_name || "#{name}_id").to_sym : nil
          }.compact
          join_statement,sort_column=object.complex_sort(params[:sort_column].split(","),parents)
          return join_statement, sort_column
        else
          return nil,@config[:public][:sort_column]
        end
      end

      def public_sort_direction
        ["asc","desc"].include?(params[:sort_direction]) ? params[:sort_directions] : @config[:public][:sort_directions]
      end
    end #module end
  end
end