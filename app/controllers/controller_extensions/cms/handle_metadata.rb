module ControllerExtensions
  module Cms
    # Used in #Managed to #handle_metadate when saving _object_.
    # If :i18n->:translation is set to _true_ than when saving #MetaData
    # it save translation as well and check if all keys is allowed to save.
    module HandleMetadata

      # Can be called as /blog/1/save_meta_translation with translation information
      # and than that saves metadata translation separately from _object_
      def save_metadata_translation
        if Lolita.config.i18n :translation
          handle_params
          @object=object.find(params[:id])
          save_metadata_with_translation()
          @notice=t(:"notice.translation saved")
          render :partial=>"/managed/meta_information", :locals=>{:tab=>params[:tab]}
        end
      end

      private

      def get_crud_metadata_object
        get_existing_crud_metadata_object || get_new_crud_metadata_object
      end

      def get_existing_crud_metadata_object
        MetaData.by_metaable(@object.id,@config[:object_name])
      end

      def get_new_crud_metadata_object
        MetaData.new(:metaable_type=>@config[:object_name].camelize,:metaable_id=>@object.id)
      end
      
      def save_metadata_with_translation
        unless @metadata || @metadata=get_existing_crud_metadata_object
          @metadata=get_new_crud_metadata_object
        end

        if my_params[:metadata] && @object.respond_to?(:allow_metadata_edit)
          allowed=@object.send(:allow_metadata_edit)
          return unless allowed
          if allowed.is_a?(Hash)
            allowed.each { |key,val|
              my_params[:metadata].delete(key) unless val
            }
          end
        end

        if Lolita.config.i18n(:translation) && my_params[:meta_translation_locale]
          #raise Globalize::Wrong language error if first language switched and then saved
          # work good if block given
          @metadata.switch_language(my_params[:meta_translation_locale]) do
            @metadata.update_attributes!(my_params[:metadata])
          end
          @metadata.switch_language(my_params[:meta_translation_locale]) #this switch object lang
        else
          @metadata.update_attributes!(my_params[:metadata])
        end
      end

      def handle_metadata
        if has_tab_type?(:metadata)
          save_metadata_with_translation()
        end
      end

      def handle_invalid_record_metadata
        if has_tab_type?(:metadata) && @metadata
          @metadata.errors.each{|attr,msg|
            @object.errors.add(attr,msg[0])
          }
        end
      end
      #beidazas funkcijas
    end
  end
end
