module Admin::TranslateHelper
  def get_locale_short
    Globalize::Locale.language_code
  end

  def all_languages_only
    all_langs = Admin::Language.find(:all)
    base_lang=Globalize::Locale.base_language
    all_combined=[[]]
    all_langs.collect{|x|
      unless x.language==base_lang
        all_combined<<["#{x.name} (#{x.short_name.upcase})",x.short_name]
      else
        all_combined[0]=["#{x.name} (#{x.short_name.upcase})",x.short_name]
      end
    }
    languages=all_combined
    current=Globalize::Locale.language_code
    select_tag("temp_locale", options_for_select(languages, current),:style=>"width:200px;float:left;")
  end

  def all_languages
    all_langs = Admin::Language.find(:all)
    base_lang=Globalize::Locale.base_language
    all_combined=[[]]

    all_langs.collect{|x|
      unless x.language==base_lang
        all_combined<<["#{x.name} (#{x.short_name.upcase})",x.short_name]
        unless @object.language_code
          @object.switch_language(x.short_name)
        end
      else
        all_combined[0]=["#{x.name} (#{x.short_name.upcase})",x.short_name]
      end

    }
    @object.switch_language(params[:locale]) if params[:locale]
    languages=all_combined
    current=@object.language_code
    select_tag("temp_locale", options_for_select(languages, current),:class=>"select")
  end
  def base_language_only
    yield if Globalize::Locale.base?
  end

  def not_base_language
    yield unless  Globalize::Locale.base?
  end

  def available_language_list
    Admin::Language.find(:all)
  end
end
