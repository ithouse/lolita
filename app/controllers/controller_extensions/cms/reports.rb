module ControllerExtensions
  module Cms
    # Deprecated!
    module Reports

      # Create <i>XML</i> or <i>CSV</i> report by calling _list_ and from response generate it.
      def report
        obj=@config[:overwrite] ? @config[:object].camelize.constantize : object
        data=list(:report=>{:full=>true})
        if params[:xls]
          headers['Content-Type'] = "application/vnd.ms-excel"
          headers['Content-Disposition'] = %(attachment; filename="#{Time.now.strftime("%Y%m%d%H%M%S")}_#{params[:controller].tableize}.xls")
          headers['Cache-Control'] = ''
          render :partial=>"/cms/standart_xls_report", :locals=>{:data=>data, :object=>obj}, :layout=>false
        else
          render :partial=>"/cms/standart_csv_report", :locals=>{:data=>list, :object=>obj}
        end
      end

      private
      def render_report
        @page
      end
      #beidzas funkcijas
    end
  end
end