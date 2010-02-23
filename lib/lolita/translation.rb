module Lolita
  module Translation
    def self.included(base) # :nodoc: 
      base.class_eval{
        include InstanceMethods
      }
    end

    module InstanceMethods
      # Set *request* locale. Set <i>session[:locale]</i>, <i>I18n.locale</i> and
      # Globalize.current_locale from <em>params[:locale]</em> or set default locale.
      def set_locale 
        session[:locale]=Lolita.config.i18n :language_code || Admin::Language.find_base_language.short_name unless session[:locale]
        unless (current_user && current_user.is_a?(Admin::SystemUser))
          switch_locale=params[:locale]
          if switch_locale && I18n.available_locales.include?(switch_locale.to_sym)
            session[:locale]=switch_locale
          end
          I18n.locale = session[:locale].to_s
          Globalize::Locale.set session[:locale].to_s
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