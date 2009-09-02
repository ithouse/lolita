module Extensions
  module Cms
    module Language
      def change_language_only
        Globalize::Locale.set("#{params[:translation_locale]}-#{params[:translation_locale]=='en' ? "US" : params[:translation_locale].upcase}")
        redirect_to :action=>'list',:is_ajax=>true,:translation_locale=>params[:translation_locale]
      end
      def change_language
        #begin
        handle_params
        Globalize::Locale.set("#{params[:translation_locale]}-#{params[:translation_locale]=='en' ? "US" : params[:translation_locale].upcase}")
        @object=object.find(params[:id])
        @object.switch_language(params[:translation_locale])
        @translation=@object.clone if @object
        # end
        render :partial=>'/managed/translate',:layout=>false,:locals=>{:read_only=>false,:tab=>params[:tab]}
        #rescue
        #end
      end
      def meta_change_language
        handle_params
        @object=object.find(params[:id])
        @metadata=MetaData.by_metaable(@object.id,@config[:object_name])
        @metadata.switch_language(params[:meta_translation_locale]) if @metadata
        render :partial=>"/managed/meta_information", :layout=>false,:locals=>{:tab=>params[:tab]}
      end
    end
  end
end