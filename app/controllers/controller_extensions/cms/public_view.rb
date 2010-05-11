module ControllerExtensions
  module Cms
    # Responsible for default #Managed actions (#index, #show).
    module PublicView

      # Default #Managed function for single resource handling.
      # Configuration is received through managed configuration :public attribute.
      # Accepted +attributes+
      # * <tt>:template</tt> - Template name to render, default "show"
      # * <tt>:layout</tt> - Layout name to render, default false
      def show
        handle_function "before_show"
        @object=object.find(:first,:conditions=>object.merge_conditions(["#{object.table_name}.#{object.primary_key}=?",get_id],@config[:public][:conditions]))
        handle_function "after_show"
        render :action=>@config[:public][:template]||"show", :layout=>@config[:public][:layout]
      end

      # Default #Managed action for many entries.
      # Accpted +attributes+
      # * <tt>:sort_column</tt> - Sort column
      # * <tt>:sort_direction</tt> - Sort direction, "asc" or "desc"
      # * <tt>:joins</tt> - Array of joins, +SQL+ format
      # * <tt>:per_page</tt> - Count of entries in one page.
      def index
        handle_function "before_show"
        join,sort_columns=public_sort_column
        @page=object.lolita_paginate(
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