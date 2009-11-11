require 'rack/utils'

module Middleware
  class PathRewrite
    def initialize(app)
      @app = app
    end
  
    def call(env)
      @env = env
      env["_PATH_INFO"]   = env["PATH_INFO"]
      env["REQUEST_PATH"] =
        env["REQUEST_URI"]  =
        env["PATH_INFO"]    = find_new_path(env["PATH_INFO"])
      @app.call(env)
    end

    private

    def find_new_path path
      path = "/" if path == "" || path.nil?
      path =~ /\/(#{I18n.available_locales.map(&:to_s).join("|")})?\/?(.*[^\/])\/?/
      if $2
        change_locale($1 || Globalize::Locale.base_language.code) unless Globalize::Locale.language
        meta = MetaData.find_by_url $2
        unless meta
          tr = Globalize::ModelTranslation.find(:first, :conditions => {:text => $2, :table_name=>"meta_datas", :facet=>"url"})
          if tr
            meta = MetaData.find tr.item_id
            change_locale(tr.language_code) unless tr.language_code == Globalize::Locale.language.code
          end
        end
        if $1
          change_locale($1) unless Globalize::Locale.language.code == $1
        else
          change_locale(Globalize::Locale.base_language.code) unless Globalize::Locale.language.code == Globalize::Locale.base_language.code
        end
        if meta && meta.metaable
          if meta.metaable.is_a?(Admin::MenuItem)
            if meta.metaable.menuable.is_a? Admin::Action
              return "/#{Globalize::Locale.language.code}/#{meta.metaable.menuable.controller.gsub(/^\//,'')}/#{meta.metaable.menuable.action}/"
            else
              controller  = meta.metaable.menuable.class.to_s.underscore.gsub("::","/")
              object_id   = meta.metaable.menuable.id
            end
          else
            controller  = meta.metaable.class.to_s.underscore.gsub("::","/")
            object_id   = meta.metaable.id
          end
          path = "/#{Globalize::Locale.language.code}/#{controller}/show/#{object_id}"
        end
      end
      path
    end

    def change_locale code
      I18n.locale = code
      @env["rack.session"][:locale] = code
      Globalize::Locale.set code
    end
  end
end
