module Extensions
  module Cms
    module Crud
      def new
        params[:action]="create"
        handle_before_create
        handle_function "before_new"
        @metadata=MetaData.new(my_params[:metadata]) if has_tab_type?(:metadata)
        @object=object.new(params[:object])
        handle_function "after_new"
        set_parent_values_to_object
        redirect_me :only_render=>true, :layout=>self_layout
      end
      
      def create
        return false unless request.post?
        begin
          params[:action]="create"
          handle_before_create
          manage_nested_params
          handle_special_fields(true)
          MetaData.transaction do
            handle_has_many_relation
            handle_function "before_create"
            @object=assign_object_attributes() unless @object
            @object.save!
            if @object.errors.empty?
              handle_metadata
              handle_after_create
              handle_after_save
              handle_function "after_create"
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
          handle_function "before_edit"
          @object=object.find_by_id(my_params[:id])
          @metadata=MetaData.by_metaable(@object.id,@config[:object_name]) || MetaData.new
          handle_function "after_edit"
          redirect_me :only_render=>true, :layout=>self_layout
        end
      end
      
      def update
        return false unless request.post?
        begin
          params[:action]='update'
          manage_nested_params
          handle_special_fields(true)
          @object=object.find_by_id(my_params[:id])
          return false unless @object
          @translation=@object.clone if Lolita.config.i18n :translation
          @metadata=MetaData.by_metaable(@object.id,@config[:object_name]) || MetaData.new
          if my_params[:object]
            if Lolita.config.i18n :translation && has_tab_type?(:translate)
              current_language=params[:translation_locale]
              base_lang = session[:locale] || Admin::Language.find_base_language.short_name
              Globalize::Locale.set("#{base_lang}-#{base_lang=='en' ? "US" : base_lang.upcase}")
              @object=object.find_by_id(my_params[:id])
            end            
            MetaData.transaction do
              handle_function "before_update"
              handle_has_many_relation
              if Lolita.config.i18n :translation && has_tab_type?(:translate)
                @object.switch_language(current_language) do
                  assign_object_attributes(@object,my_params[:translation])
                  @object.save!
                end
              end
              assign_object_attributes(@object)
              @object.save!
              if @object.errors.empty?
                handle_metadata()
                handle_special_fields()
                handle_menu()
                handle_after_save()
                handle_function "after_update"
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
        handle_function "before_destroy"
        if my_params[:list_check]
          if my_params[:list_check].is_a?(String)
            my_params[:list_check]=my_params[:list_check].to_array
          end
          if my_params[:list_check].respond_to?("each")
            my_params[:list_check].each{|id|
              rec=object.find_by_id(id)
              rec.destroy() if rec
            }
          end
        else
          rec=object.find_by_id(my_params[:id])
          rec.destroy if rec
        end
        handle_function "after_destroy"
        redirect_me
      end

      private

      def assign_object_attributes(obj=nil,data=nil)
        obj=object.new unless obj
        (data || my_params[:object]).each{|k,v|
          obj.send(:"#{k}=",v)
        }
        obj
      end
    end
  end
end
