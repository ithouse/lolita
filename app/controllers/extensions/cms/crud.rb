module Extensions
  module Cms
    module Crud

      def new
        params[:action]="create"
        handle_before_create
        handle_before_functions 'new'
        @metadata=MetaData.new(my_params[:metadata]) if has_tab_type?(:metadata)
        @object=object.new(params[:object])
        handle_after_functions 'new'
        set_parent_values_to_object
        redirect_me :only_render=>true, :layout=>self_layout
      end
      
      def create
        return false unless request.post?
        begin
          params[:action]="create"
          handle_before_create
          handle_special_fields(true)
          MetaData.transaction do
            handle_has_many_relation
            @object=object.new(my_params[:object])
            handle_before_functions 'create'
            @object.save!
            if @object.errors.empty?
              handle_metadata
              handle_after_create
              handle_after_save
              handle_after_functions 'create'
              redirect_step_back? ? redirect_me(:step_back=>true) : redirect_me
            else
              redirect_me :error=>true
            end
          end
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
          handle_function "on_save_error"
          handle_invalid_record_metadata
          redirect_me :error=>true
        end
      end

      def edit
        params[:action]="update"
        if (my_params[:id].to_i==0)  && !my_params[:object]
          redirect_to :action=>"new", :all=>@config[:all_params]
        else
          handle_before_functions 'edit'
          @object=object.find_by_id(my_params[:id])
          @metadata=MetaData.by_metaable(@object.id,@config[:object_name])
          handle_after_functions 'edit'
          redirect_me :only_render=>true, :layout=>self_layout
        end
      end
      
      def update
        return false unless request.post?
        begin
          params[:action]='update'
          handle_special_fields(true)
          @object=object.find_by_id(my_params[:id])
          return false unless @object
          @translation=@object.clone if Lolita.config.translation
          @metadata=MetaData.by_metaable(@object.id,@config[:object_name]) || MetaData.new
          if my_params[:object]
            if Lolita.config.translation && has_tab_type?(:translate)
              current_language=params[:translation_locale]
              base_lang = session[:locale] || Admin::Language.find_base_language.short_name
              Globalize::Locale.set("#{base_lang}-#{base_lang=='en' ? "US" : base_lang.upcase}")
              @object=object.find_by_id(my_params[:id])
            end            
            MetaData.transaction do
              handle_before_functions 'update'
              handle_has_many_relation
              if Lolita.config.translation && has_tab_type?(:translate)
                @object.switch_language(current_language) do
                  @object.update_attributes!(my_params[:translation])
                end
              end
              @object.update_attributes!(my_params[:object])
              if @object.errors.empty?
                handle_metadata()
                handle_special_fields()
                handle_menu()
                handle_after_save()
                handle_after_functions 'update'
                #                unless @object.errors.empty?
                #                  raise ActiveRecord::RecordInvalid
                #                end
                redirect_me
              else
                redirect_me :error=>true, :layout=>true
              end
            end
          else
            redirect_me :error=>true, :layout=>true
          end
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
          handle_function "on_save_error"
          handle_invalid_record_metadata
          redirect_me :error=>true
        end
      end

      def destroy
        handle_before_functions 'destroy'
        # exo_ids=[]
        if my_params[:list_check]
          if my_params[:list_check].is_a?(String)
            my_params[:list_check]=my_params[:list_check].to_array
          end
          begin
            if my_params[:list_check].respond_to?("each")
              my_params[:list_check].each{|id|
                rec=object.find_by_id(id)
                rec.destroy() if rec
              }
            end
          rescue
            raise "Nevar izdzēst ierakstu(-s)!"
          end
        else
          rec=object.find_by_id(my_params[:id])
          rec.destroy if rec
        end
     
        handle_after_functions 'destroy'
        redirect_me
      end
    end
  end
end
