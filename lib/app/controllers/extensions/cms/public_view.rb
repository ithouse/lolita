module Extensions
  module Cms
    module PublicView
      #Pieejamās opcijas var tikt norādītas jau konfigurācijā, vai arī iekš before_show funkcijas
      # :conditions=>tiek pievienots find, kā :conditions
      # :sort_column=>kolonnu(-as) nosaukums(-i), ja vairāki atdalīti ar komatiem
      # :sort_direction=>kārtošanas virziens, jēga tikai tad ja ir kārtošnas kolonna(-as)
      # :single=> vai atlasīt vienu vai vairākus ierakstus, ja tiek atlasīti vairāki, tad tie pieejami caur
      #           @page, ja viens tad caur @object, @page ir Ith.Paginator klases objekts
      # :per_page => cik ierakstus iekļaut atlasēs lapā, pēc noklusējuma Ith.Paginator noklusētais
      # :joins=>SQL, kas joino ar saistītajām tabulām
      def show
        if @config[:public]
          handle_before_functions "show"
          error=false
          @config[:public][:conditions]||=[]
          @config[:public][:conditions]=object.cms_merge_conditions(@config[:public][:conditions],valid_filter_from_params)
          @config[:public][:conditions]=@config[:public][:conditions].empty? ? nil : @config[:public][:conditions]
          if @config[:public][:single] && get_id.to_i>0
            @object=object.find_by_id(get_id,:conditions=>@config[:public][:conditions])
            error=true unless @object
          elsif !@config[:public][:single] && get_id.to_i<1
            join,sort_columns=public_sort_column
            @page=object.paginate(
              :conditions=>@config[:public][:conditions],
              :sort_directions=>public_sort_direction,
              :joins=>((@config[:public][:joins] || [])+(join||[])).uniq,
              :sort_column=>sort_columns,
              :per_page=>@config[:public][:per_page],
              :page=>params[:page].to_i
            )
            
          else
            error=true
          end
          handle_after_functions "show" unless error
          error ? redirect_view(:error=>true) : redirect_view(:only_layout=>true)
        end
      end
      
      private

      def valid_filter_from_params
        sql=""
        values=[]
        params.each{|key,value|
          if value.to_i>0 && key.to_s.match(/\w+_id$/) &&  object.respond_to?(key)
            sql<<" `#{object.table_name}`.`#{key}`=?"
            values<< value.to_i
          end
        }
        return [sql]+values
      end

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