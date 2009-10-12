module Lolita
  module Translation
    def self.included(base)
      base.class_eval{
        include InstanceMethods
        before_filter :set_locale
      }
    end

    module InstanceMethods
      def set_locale
        if Admin::User.area==:public
          I18n.locale=session[:locale]
          if params[:locale] && I18n.available_locales.include?(params[:locale].to_sym)
            I18n.locale = params[:locale]
            session[:locale]=params[:locale]
          end
          Globalize::Locale.set I18n.locale.to_s
        else
          locale=Lolita.config.i18n :language_code || Admin::Language.find_base_language.short_name
          I18n.locale=locale
          Globalize::Locale.set locale
        end
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
  end
end