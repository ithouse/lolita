module Extensions
  module Cms
    module Language
      def change_language_only
        Globalize::Locale.set("#{params[:temp_locale]}-#{params[:temp_locale]=='en' ? "US" : params[:temp_locale].upcase}")
        redirect_to :action=>'list',:is_ajax=>true,:temp_locale=>params[:temp_locale]
      end
      def change_language
        #begin
        handle_params
        Globalize::Locale.set("#{params[:temp_locale]}-#{params[:temp_locale]=='en' ? "US" : params[:temp_locale].upcase}")
        @object=object.find(params[:id])
        @object.switch_language(params[:temp_locale])
        @translation=@object.clone if @object
        # end
        render :partial=>'/managed/translate',:layout=>false,:locals=>{:read_only=>false,:tab=>params[:tab]}
        #rescue
        #end
      end
    end
  end
end