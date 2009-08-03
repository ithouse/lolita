module Extensions::TranslationHelper
  def t key
    # in Lolita's tempaltes you can use translations the same way as in the main project
    # with shortcuts like ".login_name" what will be the same as "lolita.admin.user.login.login_name"
    if key.to_s.first == "."
      I18n.t("lolita." + template.path_without_format_and_extension.gsub(%r{/_?}, ".") + key.to_s)
    else
      I18n.t key
    end
  end
end