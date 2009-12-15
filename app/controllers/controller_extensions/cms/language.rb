module ControllerExtensions
  module Cms
    # Do language changing in _object_ create/edit form
    module Language

      # Change language for whole administrative side and redirects to <i>list</i> action.
      def change_language_only
        Globalize::Locale.set("#{params[:translation_locale]}-#{params[:translation_locale]=='en' ? "US" : params[:translation_locale].upcase}")
        redirect_to :action=>'list',:is_ajax=>true,:translation_locale=>params[:translation_locale]
      end

      # Change _object_ language in *translation* tab.
      # Receive +params+
      # * <tt>:translation_locale</tt> - Locale code ('en','ru') to switch _object_ language.
      # * <tt>:id</tt> - _Object_ id.
      # * <tt>:tab</tt> - Tab index where the translation section is.
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

      # Change _metadata_ language.
      # Receive +params+
      # * <tt>:id</tt> - _Object_ id (note that it isn't _metadata_ id).
      # * <tt>:meta_translation_locale</tt> - Language code.
      # * <tt>:tab</tt> - Tab index where _metadata_ tab is.
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