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
        base_lang = Lolita.config.i18n :language_code || Admin::Language.find_base_language.short_name
        Globalize::Locale.set("#{base_lang}-#{base_lang=='en' ? "US" : base_lang.upcase}")
        @translation=object.find(params[:id]) #TODO pārbaudīt vai to dara, vajag lai nepārraksta objektu
        @translation.switch_language(params[:translation_locale])
        @object=object.find(params[:id])
        @object.switch_language(params[:translation_locale])
        render :partial=>'/managed/translate',:layout=>false,:locals=>{:read_only=>false,:tab=>params[:tab]}
        #rescue
        #end
      end
      def meta_change_language
        handle_params
        flash[:notice]=nil
        @object=object.find(params[:id])
        @metadata=MetaData.by_metaable(@object.id,@config[:object_name])
        @metadata.switch_language(params[:meta_translation_locale]) if @metadata
        render :partial=>"/managed/meta_information", :layout=>false,:locals=>{:tab=>params[:tab]}
      end
    end
  end
end