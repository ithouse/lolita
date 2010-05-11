# coding:utf-8
module Lolita
  module MetaUrl
    def self.included(base) # :nodoc:
      base.class_eval{
        include InstanceMethods
      }
      base.alias_method_chain :url_for, :meta_url
    end

    module InstanceMethods

      def url_for_with_meta_url(options={})
        if options.is_a?(Hash) && options[:id].is_a?(Cms::Manager) && @object
           if @object.respond_to?(:slug)
             options[:id]=options[:id].slug
           else
             options[:id]=get_id(options[:id])
           end
        end
        url_for_without_meta_url(options)
      end

      def get_id(object=nil,controller=nil)
        object ? (object.is_a?(Symbol) ? get_url_for(object,controller) : make_url_for(object)) : get_url_for
      end

      def make_url_for(object)
        url = ""
        meta_data=MetaData.find_by_object(object)
        url = meta_data.url if meta_data
        url = object.id if url.blank?
        url
      end

      def get_url_for(name=nil,controller=nil)
        name||=:id
        if params[name] && (params[name].is_a?(Integer) || (params[name].to_i.to_s.size==params[name].to_s.size))
          params[name].to_i
        else
          meta_data=MetaData.by_metaable(params[name]||params[:meta_url],controller || params[:controller])
          meta_data.metaable_id if meta_data
        end
      end

    #  def url_for options={}
    #
    #    urs=Admin::UrlScope.find_by_name(options[:controller])
    #    md=MetaData.by_metaable options[:id],options[:controller]
    #    if urs && md && md.url.to_s.size>0 && options[:action].to_s=="show"
    #      options[:controller]=(options[:controller].first=="/" ? "/" : "" )+urs.scope
    #      options.delete(:id) if options[:id]
    #      options[:action]=md.url
    #      # options[:meta_url]=md.url
    #    elsif options[:controller]=='start_page'
    #      options[:controller]="/"
    #      options[:action]=nil
    #    elsif urs && options[:action]=='show'
    #      options[:controller]=(options[:controller].first=="/" ? "/" : "" )+urs.scope
    #      options[:action]= nil
    #    else
    #      unless Admin::Language.find_base_language.short_name==Globalize::Locale.language_code
    #        unless options.is_a?(String) ||  options.has_key?(:locale)
    #          options[:locale]=params[:locale]
    #        end
    #      end
    #    end
    #    super options
    #  end

    end
  end
end