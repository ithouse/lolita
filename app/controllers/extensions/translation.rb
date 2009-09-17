module Extensions::Translation
  def set_locale
    I18n.locale=session[:locale]
    if params[:locale] && I18n.available_locales.include?(params[:locale].to_sym)
      I18n.locale = params[:locale]
      session[:locale]=params[:locale]
    end
    Globalize::Locale.set I18n.locale.to_s
  end

  def extract_locale_from_tld
    parsed_locale = request.host.split('.').last
    (parsed_locale && I18n.available_locales.include?(parsed_locale.to_sym)) ? parsed_locale : nil
  end

  def extract_locale_from_subdomain
    parsed_locale = request.subdomains.first
    (parsed_locale && I18n.available_locales.include?(parsed_locale.to_sym)) ? parsed_locale : nil
  end

  def extract_locale_from_accept_language_header
    parsed_locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    (parsed_locale && I18n.available_locales.include?(parsed_locale.to_sym)) ? parsed_locale : nil
  end
end
