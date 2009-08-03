module Extensions
  module Cms
    module HandleParams

      #Handl params ir vienota funkcija visām funkcionālajām metodēm kā edit,list,create un delete
      #tā nodrošina vienotu parametru apstrādes stilu un tātad arī rezultātu atgriešanu
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

      #šī funkcija ir domāta lai norādītu parametrus, kas tiek iegūti zsaucot citas funkcijas
      def get_special_params
        set_back_url
        @config[:refresh_menu]=my_params[:refresh_menu].to_b
        @config[:namespace]=namespace
        @config[:object_name]=my_params[:controller]
        @config[:all_params]=my_params
        @config[:object_class]=get_object_klass
      end
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
      #funkcija kas satur mainīgo all_params kas rodas saņemot parametros :all
      def all_params
        @config[:all_params]
      end

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

      def set_parent_values_to_object
        my_params.each{|key,value|
          if key.to_s.include?("_id") && (!@config[:parents] || (@config[:parents] && @config[:parents].include?(key.to_sym))) && @object.respond_to?(key.to_s)
            @object.send("#{key.to_s}=",value)
          end
        }
      end

      #Funkcija no ienākošajiem parametriem var izdot tikai tos kuri atbilsts
      #vecāka elementa kritērijiem, pēc noklusējuma,tas ir kaut_kas_id
      def get_parents_from_params object=nil,parent_name=false,pattern="_id"
        object.each{|key,value|
          if key.to_s.include?(pattern) && !key.to_s.include?("temp")
            key=key.sub(/#{pattern}/,"").to_sym if parent_name
            yield key,value
          end
        }
      end


      #beidzas funkcijas
    end
  end
end