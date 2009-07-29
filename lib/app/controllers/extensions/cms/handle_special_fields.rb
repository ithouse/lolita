module Extensions
  module Cms
    module HandleSpecialFields

      #TODO pielikt lai ar laiku var atbrīvoties no pārējiem lauku handliem un iztik ar šo vienu
      def handle_special_fields before_save=false
        special_field_types=[:autocomplete]
        @special_fields={} if before_save
        if before_save
          @config[:tabs].each_with_index{|tab,tab_index|
            tab_fields=tab_fields(tab)
            tab_fields.each_with_index{|field,index|
              if special_field_types.include?(field[:type].to_sym) && ((field[:actions] && field[:actions].include?(params[:action].to_sym) || !field[:actions]))
                @special_fields["#{tab_index}_#{index}"]=my_params[tab[:object]||:object][field[:field]] if my_params[tab[:object]||:object][field[:field]]
                my_params[tab[:object]||:object].delete(field[:field]) if field[:remove_from_params]
              end
            }
          } if request.post?
        else
          @special_fields.each{|key,data|
            tab,field=key.split("_")
            tab=tab.to_i
            field=field.to_i
            field=tab_fields(@config[:tabs][tab])[field]
            case field[:type]
            when :autocomplete
              save_autocomplete(field,data)
            end
          }
        end
      end

      private

      def save_autocomplete field,data
        @object.send(field[:save_method],data)
      end
      
    end
  end
end
