module Extensions::TranslationHelper
  def all_languages id,current_object
    all_langs = Admin::Language.find(:all,:include=>:globalize_language,:order=>"is_base_locale desc")
    base_lang=Globalize::Locale.base_language
    languages=all_langs.collect{|x|
      unless x.language==base_lang
        ["#{x.name} (#{x.short_name.upcase})",x.short_name]
#        unless current_object.language_code
#          current_object.switch_language(x.short_name)
#        end
      else
        ["#{x.name} (#{x.short_name.upcase})",x.short_name]
      end
    }
    #current_object.switch_language(params[:locale]) if params[:locale]
    #languages=all_combined
    current=current_object.language_code
    select_tag(id, options_for_select(languages, current),:class=>"select")
  end

  def t key,options={}
    # in Lolita's tempaltes you can use translations the same way as in the main project
    # with shortcuts like ".login_name" what will be the same as "lolita.admin.user.login.login_name"

    if key.to_s.first == "."
      begin
        # first try normal call
        I18n.t(template.path_without_format_and_extension.gsub(%r{/_?}, ".") + key.to_s, {:raise => true}.merge(options))
      rescue I18n::MissingTranslationData
        # try with lolita's prefix
        begin
          I18n.t("lolita." + template.path_without_format_and_extension.gsub(%r{/_?}, ".") + key.to_s, {:raise => true}.merge(options))
        rescue I18n::MissingTranslationData
          # call normal again and and return exception
          I18n.t(template.path_without_format_and_extension.gsub(%r{/_?}, ".") + key.to_s,options)
        end
      end
    else
      I18n.t key,options
    end
  end
end


