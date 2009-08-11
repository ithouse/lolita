module Extensions::TranslationHelper
#  def all_languages
#    all_langs = Admin::Language.find(:all)
#    base_lang=Globalize::Locale.base_language
#    all_combined=[[]]
#
#    all_langs.collect{|x|
#      unless x.language==base_lang
#        all_combined<<["#{x.name} (#{x.short_name.upcase})",x.short_name]
#        unless @object.language_code
#          @object.switch_language(x.short_name)
#        end
#      else
#        all_combined[0]=["#{x.name} (#{x.short_name.upcase})",x.short_name]
#      end
#
#    }
#    @object.switch_language(params[:temp_locale] || base_lang.code) #if params[:locale]
#    languages=all_combined
#    current=@object.language_code
#    select_tag("translation_locale", options_for_select(languages, current),:class=>"select")
#  end

  def t key
    # in Lolita's tempaltes you can use translations the same way as in the main project
    # with shortcuts like ".login_name" what will be the same as "lolita.admin.user.login.login_name"
    lolitas_views = Dir.glob("#{RAILS_ROOT}/vendor/plugins/lolita/app/views/*").collect {|d| File.basename(d)}
    view_prefix = template.path_without_format_and_extension.split("/")[0]
    if key.to_s.first == "."
      if lolitas_views.include?(view_prefix)
        I18n.t("lolita." + template.path_without_format_and_extension.gsub(%r{/_?}, ".") + key.to_s)
      else
        I18n.t(template.path_without_format_and_extension.gsub(%r{/_?}, ".") + key.to_s)
      end
    else
      I18n.t key
    end
  end
end


