module Extensions
  module Cms
    module HandleMetadata

      def save_metadata_translation
        handle_params
        @object=object.find(params[:id])
        unless @metadata=MetaData.by_metaable(@object.id,@config[:object_name])
          @metadata=MetaData.create!
        end
        #raise Globalize::Wrong language error if first language switched and then saved
        # work good if block given
        @metadata.switch_language(params[:meta_translation_locale]) do
          @metadata.update_attributes!(params[:metadata])
        end
        @metadata.switch_language(params[:meta_translation_locale]) #this switch object lang 
        flash[:notice]=t(:"metadata.translation saved")
        render :partial=>"/managed/meta_information", :locals=>{:tab=>params[:tab]}
      end
      
      def handle_metadata
        if has_tab_type?(:metadata)
          if !@metadata
            @metadata=MetaData.new(my_params[:metadata])
            all_metadata=MetaData.find(:all,:conditions=>["metaable_type=? AND metaable_id=? AND id!=?",@object[:object_name],@object.id,@metadata.id]) 
            all_metadata.each{|md| md.destroy}
          elsif !@metadata.new_record?
            @metadata.update_attributes!(my_params[:metadata])
          end
          if @metadata && @metadata.new_record?
            @metadata.metaable_id=@object.id
            @metadata.metaable_type=@config[:object_name].camelize
            @metadata.save!
          end
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
