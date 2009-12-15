module ControllerExtensions
  module Cms
    module HandleParams

      # Handle all incoming params and create <em>instance variables</em> that uses other #Managed modules.
      def handle_params
        if params[:all]
          params[:all].each{|key,value|  params[key]=value if (!params[key] && key.to_sym!=:controller && key.to_s!=:action)}
          params.delete(:all)
        end
        @my_params=params.dup
        @container=@my_params[:container]||nil
        if @my_params[:object]
          @menu_record=@my_params[:object][:menu_record]
          @my_params[:object].delete(:menu_record)
        else
          @my_params[:object]={}
        end
        process_options
        get_special_params
      end

      # Set special values in <tt>@config</tt> to be used in any place in code.
      # Available <b>special values</b> in <tt>@config</tt>
      # * <tt>:refresh_menu</tt> - Detect if menu need to be refreshed
      # * <tt>:namespace</tt> - Current namepsace of controller
      # * <tt>:object_name</tt> - Controller name (Deprecated)
      # * <tt>:all_params</tt> - All params (Deprecated)
      # * <tt>:object_class</tt> - Class of _object_
      #
      def get_special_params
        set_back_url
        @config[:refresh_menu]=my_params[:refresh_menu].to_b
        @config[:namespace]=namespace
        @config[:object_name]=my_params[:controller]
        @config[:all_params]=my_params
        @config[:object_class]=get_object_klass
      end

      # Get _object_ class.
      # _Object_ class can be specified in these ways in <tt>@config</tt>
      # * <tt>:object</tt> is a <tt>Hash</tt>, than can be specified <tt>:default</tt>
      #   _object_ class or for any action.
      # * <tt>:object</tt> is a <tt>String</tt>
      #
      def get_object_klass
        if @config[:object]
          if @config[:object].is_a?(Hash)
            object_class=@config[:object][params[:action].to_sym]
            object_class=@config[:object][:default] unless object_class
          else
            object_class=@config[:object]
          end
          object_class.camelize.constantize if object_class
        else
          params[:controller].camelize.constantize
        end
        #@config[:object] ? @config[:object].camelize.constantize : params[:controller].camelize.constantize
      end

      # Deprecated.
      def all_params
        @config[:all_params]
      end

      # Used in #Managed when redirecting.
      # Set special params and parent params.
      def additional_params
        id=@object.id if @object
        p={
          :action=>final_action,
          :is_ajax=>my_params[:is_ajax] || request.xml_http_request?,
          :id=>id,
          :refresh_menu=>(@menu_record && @menu_record.is_a?(Hash)),
          :paging=>my_params[:paging],
          :page=>my_params[:page]
        }

        my_params.each{|key,value|
          related_object=key.to_s.gsub(/_id$/,"") if key.to_s.match(/_id$/)
          p[key]=value if related_object && (@object.respond_to?(related_object.pluralize) || @object.respond_to?(related_object))
          related_object=nil
        }
        return p
      end

      # Set values from params to <tt>@object</tt> when opening new _object_ form.
      def set_parent_values_to_object
        my_params.each{|key,value|
          if key.to_s.include?("_id") && (!@config[:parents] || (@config[:parents] && @config[:parents].include?(key.to_sym))) && @object.respond_to?(key.to_s)
            @object.send("#{key.to_s}=",value)
          end
        }
      end

      # Yield only these params that match given pattern
      def get_parents_from_params object=nil,parent_name=false,pattern="_id"
        object.each{|key,value|
          if key.to_s.include?(pattern) && !key.to_s.include?("temp")
            key=key.sub(/#{pattern}/,"").to_sym if parent_name
            yield key,value
          end
        }
      end

    end
  end
end