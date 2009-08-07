module Extensions::TranslationHelper
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