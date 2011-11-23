module Lolita
  module Controllers
    module InternalHelpers
      extend ActiveSupport::Concern
      included do
        helper LolitaHelper
        #TODO pārnest helperus uz lolitu vai arī uz lolita app nevis likt iekš controllers iekš lolitas
        helpers = %w(resource resource_name 
                     resource_class lolita_mapping show_response tab_form tab_form=)
        hide_action *helpers
       
        helper_method *helpers
        prepend_before_filter :is_lolita_resource?
        prepend_around_filter :switch_locale
      end

      # Return instance variable named as resource
      # For 'posts' instance variable will be @posts
      def resource
        instance_variable_get(:"@#{resource_name}")
      end
      
      def resource_name
        lolita_mapping.class_name.underscore.to_sym
      end
      
      def resource_class
        lolita_mapping.to
      end
      
      def lolita_mapping
        @lolita_mapping||=request.env["lolita.mapping"]
      end

      def tab_form=(form)
        @tab_form = form
      end

      def tab_form(temp_form = nil)
        if block_given?
          old_form = @tab_form
          @tab_form = temp_form
          content = yield
          @tab_form = old_form
        end
        @tab_form
      end
      
      protected

      def notice(msg)
        response.headers["Lolita-Notice"] = Base64.encode64(msg)
      end

      def alert(msg)
        response.headers["Lolita-Alert"] = Base64.encode64(msg)
      end

      def error(msg)
        response.headers["Lolita-Error"] = Base64.encode64(msg)
      end

      def is_lolita_resource?
        raise ActionController::UnknownAction unless lolita_mapping
      end

      def resource=(new_resource)
        instance_variable_set(:"@#{resource_name}",new_resource)
      end

      def resource_attributes
        fix_attributes(params[resource_name] || {})
      end

      def resource_with_attributes(current_resource,attributes={})
        attributes||=resource_attributes
        attributes.each{|key,value|
          current_resource.send(:"#{key}=",value)
        }
        current_resource
      end

      def get_resource(id=nil)
        self.resource = resource_class.lolita.dbi.find_by_id(id || params[:id])
      end

      def build_resource(attributes=nil)
        self.run(:before_build_resource)
        attributes||=resource_attributes
        self.resource=resource_with_attributes(resource_class.new,attributes)
        self.run(:after_build_resource)
      end

      def build_response_for(conf_part,options={})
        # FIXME when asked for some resources that always create new object, there may
        # not be any args, like lolita.report on something like that
        @component_options = options
        @component_object = resource_class.lolita.send(conf_part.to_sym)
        @component_builder = @component_object.build(@component_options)
      end
      

      private

      def fix_attributes attributes
        fix_rails_date_attributes attributes
      end

      def fix_rails_date_attributes attributes
        #{"created_at(1i)"=>"2011", "created_at(2i)"=>"4", "created_at(3i)"=>"19", "created_at(4i)"=>"16", "created_at(5i)"=>"14"}
        date_attributes = {}
        attributes.each_pair do |k,v|
          if k.to_s =~ /(.+)\((\d)i\)$/
            date_attributes[$1] = {} unless date_attributes[$1]
            date_attributes[$1][$2.to_i] = v.to_i
            attributes.delete(k)
          end
        end
        date_attributes.each_pair do |k,v|
          unless v.detect{|index,value| value == 0 && index<4}
            attributes[k] = v.size == 3 ? Date.new(v[1],v[2],v[3]) : Time.new(v[1],v[2],v[3],v[4],v[5])
          end
        end
        attributes
      end

      def switch_locale
        old_locale=::I18n.locale
        Lolita.locale=params[:locale]
        ::I18n.locale=Lolita.locale
        yield
        ::I18n.locale=old_locale
      end
    end
  end
end